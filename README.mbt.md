# MoonMARC

MoonMARC 是一个纯 MoonBit 实现的 MARC 21 / ISO 2709 书目记录处理工具包，目标是为数字图书馆、档案馆、大学目录和数字人文项目提供可复用的底层解析能力。

> 当前版本已完成 ISO 2709 解析与序列化内核、MARC 字段查询表达式、ISBN/ISSN 校验、基础书目语义校验、JSON 双向转换和 CLI 集成。MARCXML、隐私脱敏、语义 Diff、统计与 Wasm 查看器将在后续阶段加入。

## 为什么是 MARC

MARC 21 是图书馆系统之间交换书目数据的长期标准。它使用 ISO 2709 的记录布局：

```text
24-byte Leader
Directory entries
Field terminator (0x1E)
Variable fields
Record terminator (0x1D)
```

MoonMARC 不把记录解析成未经约束的字符串，而是保留 Leader、字段、指示符和子字段的结构，使上层应用可以继续进行校验、转换、脱敏或统计。

## 已实现能力

- 有界 `Reader`：防止越界读取，支持 ASCII、十进制数字与 UTF-8 解码
- Leader：24 字节校验、记录长度、Base Address、Entry Map 和常用位置字段
- Directory：标准 MARC 21 的 `3 + 4 + 5 + 0 = 12` 字节 Entry 解析
- 字段：控制字段 `001-009`、数据字段、两个 Indicator、`0x1F` 子字段分隔符
- 记录流：解析单条记录和连续拼接的多记录 `.mrc` 数据
- ISO 2709 序列化：从 `MarcRecord` 自动生成 Directory、字段长度、字段偏移、Base Address 和记录终止符
- Round-trip：`parse → serialize → parse` 保留字段结构，序列化时拒绝非法 Tag、控制字段类型和 ISO 2709 分隔符
- 诊断：截断记录、长度不匹配、Directory 终止符缺失、字段越界、字段终止符缺失、非法 UTF-8、畸形子字段等
- 查询：按 Tag 查字段，支持 `245$a` 等查询表达式及常用书目字段快捷方法
- 标识符：ISBN-10、ISBN-13 和 ISSN 校验，支持空格与连字符
- 语义校验：缺失题名、非法 245 指示符、无效 ISBN/ISSN 和重复控制号诊断
- JSON：结构化记录与 JSON 文本双向转换，支持单条记录和多记录数组
- CLI：`inspect`、`validate`、`show`、`query`，其中 `validate` 同时执行结构与语义校验

## MoonBit API

```moonbit nocheck
let records = @moonmarc.parse_records(bytes)
for result in records {
  match result {
    Err(error) => println(error.to_string())
    Ok(record) => {
      println(record.title().unwrap_or("Untitled"))
      println(record.control_number().unwrap_or(""))
      for isbn in record.isbn_list() {
        println(isbn)
      }
    }
  }
}
```

## ISO 2709 序列化

`serialize_record` 将结构化 `MarcRecord` 写回标准 ISO 2709 二进制记录。它保留原 Leader 的业务位置，同时自动覆盖记录长度、Base Address、Indicator/Subfield 长度和 Directory Entry Map，固定生成 MARC 21 常用的 `3 + 4 + 5 + 0`（`4500`）Directory 格式。

```moonbit nocheck
///|
let record = @moonmarc.parse_record(raw).unwrap()

///|
let encoded = @moonmarc.serialize_record(record).unwrap()

// 可将多个记录合并为连续的 .mrc 数据流。

///|
let stream = @moonmarc.serialize_records([record]).unwrap()
```

序列化器会拒绝不符合记录布局的结构化数据，例如把 `001-009` 控制 Tag 写成数据字段、非 ASCII 的 Indicator 或子字段代码、超过 Directory 可表示长度的字段，以及包含 `0x1D`、`0x1E` 或 `0x1F` 保留分隔符的字段内容。

常用方法包括：

```text
record.leader()
record.fields()
record.fields_by_tag("650")
record.subfields("245", 'a')
record.first_subfield("245", 'a')
record.control_number()
record.title()
record.subtitle()
record.primary_author()
record.other_authors()
record.publisher()
record.publication_year()
record.languages()
record.subjects()
record.summary()
record.isbn_list()
```

## JSON 转换

MoonMARC 已提供 MARC 21 结构化记录与 JSON 之间的双向转换。JSON 设计保留 Leader、字段顺序、重复字段、Indicator 和子字段顺序，适合与 Web API、数据分析脚本和其他目录系统交换。

单条记录的 JSON 形状如下：

```json
{
  "leader": "00000nam a2200000 i 4500",
  "fields": [
    { "tag": "001", "value": "book-0001" },
    {
      "tag": "245",
      "indicators": ["1", "0"],
      "subfields": [
        { "code": "a", "value": "MoonBit 编程实践" },
        { "code": "c", "value": "示例作者" }
      ]
    }
  ]
}
```

控制字段使用 `value`，数据字段使用 `indicators` 和 `subfields`。多条记录使用 JSON 数组；导入时会检查 Leader、Tag、Indicator、子字段代码和字段类型，错误会返回结构化 `JsonConversionError`。

```moonbit nocheck
///|
let json_text = @moonmarc.record_to_json_text(record, indent=2)

///|
let record = @moonmarc.record_from_json_text(json_text).unwrap()

///|
let records_text = @moonmarc.records_to_json_text([record])

///|
let records = @moonmarc.records_from_json_text(records_text).unwrap()
```

JSON 转换可以直接衔接 ISO 2709：`JSON text → MarcRecord → serialize_record → .mrc`。序列化阶段会重新计算记录长度、Directory 和 Base Address，因此输出记录的 Leader 长度字段以实际二进制记录为准。
## CLI

使用 MoonBit 工具链运行：

```powershell
# 查看记录数和解析错误
moon run cmd/main -- inspect books.mrc

# 输出有效/错误数量和诊断
moon run cmd/main -- validate books.mrc

# 查看第 1 条记录（记录序号从 1 开始）
moon run cmd/main -- show books.mrc 1

# 查询每条记录的 245$a
moon run cmd/main -- query books.mrc '245$a'
```

CLI 在本地读取文件，解析失败时输出可读诊断。库本身不依赖文件系统，因此可以被浏览器 Wasm 或其他 MoonBit 程序复用。

## 数据模型

```moonbit nocheck
///|
pub(all) enum MarcField {
  ControlField(tag~ : String, value~ : String)
  DataField(
    tag~ : String,
    indicator1~ : Char,
    indicator2~ : Char,
    subfields~ : Array[Subfield]
  )
}

///|
pub(all) struct MarcRecord {
  leader : Leader
  fields : Array[MarcField]
}
```

ISO 2709 的字段长度和起始位置以 Directory 为准。MoonMARC 会先验证 Leader 与 Directory，再按绝对偏移读取字段，并在字段边界内检查终止符，避免把损坏数据静默解析成错误书目。

## 测试覆盖

当前测试覆盖：

- Reader 的 ASCII、十进制和 UTF-8
- Leader 的正常解析与非法 Entry Map
- 标准 Directory Entry
- 中文题名和控制号
- 连续多记录流
- 截断记录
- Leader 长度不匹配
- 缺失 Directory 终止符
- 越界字段
- 缺失字段终止符
- 缺失记录终止符
- 非法 UTF-8
- ISO 2709 序列化后的 Leader、Directory 与字段结构 Round-trip
- 拼接多记录流的序列化与重新解析
- 序列化时的控制字段类型与保留分隔符拒绝
- 常用书目字段快捷查询
- ISBN-10、ISBN-13 与 ISSN 校验
- `245$a` 查询表达式解析
- 题名、指示符、标识符和重复控制号语义校验
- JSON 单条/多条记录转换及 JSON → ISO 2709 集成 Round-trip

验证命令：

```powershell
moon fmt
moon check --target all
moon test
moon info
```

## 项目结构

```text
binary/       有界二进制读取器和字节工具
leader/       MARC 21 Leader
 directory/   ISO 2709 Directory
record/       记录、字段、子字段和高层查询
iso2709/      单记录和多记录解析
formats/marcjson/ JSON 双向转换
identifiers/  ISBN 与 ISSN 校验
query/        MARC 子字段查询表达式
validation/   书目语义校验和诊断
cmd/main/     CLI
```

## 路线图

1. 扩展 MARC 21 字段与子字段规则库
2. MARCXML、CSV 等更多格式转换
3. 隐私扫描、规则驱动脱敏和审计报告
4. 记录语义 Diff 与数据集统计
5. 浏览器本地 Wasm 查看器

## 隐私说明

MARC 数据可能包含采购备注、馆藏位置、本地 9XX 字段、内部 URL、电子邮箱、电话号码或其他个人信息。未来的隐私扫描和脱敏功能只能作为辅助工具使用：

> MoonMARC 只能提供技术层面的辅助检测，不能保证识别全部个人信息，正式公开数据前仍需人工审核。

## 许可证

Apache-2.0，见 [LICENSE](LICENSE)。
