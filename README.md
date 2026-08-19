# MoonMARC

MoonMARC 是一个纯 MoonBit 实现的 MARC 21 / ISO 2709 书目记录处理工具包，目标是为数字图书馆、档案馆、大学目录和数字人文项目提供可复用的底层解析能力。

> 当前版本已完成 ISO 2709 解析内核、MARC 字段查询表达式、ISBN/ISSN 校验、基础书目语义校验和 CLI 集成。JSON、MARCXML、隐私脱敏、语义 Diff、统计与 Wasm 查看器将在后续阶段加入。

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
- 诊断：截断记录、长度不匹配、Directory 终止符缺失、字段越界、字段终止符缺失、非法 UTF-8、畸形子字段等
- 查询：按 Tag 查字段，支持 `245$a` 等查询表达式及常用书目字段快捷方法
- 标识符：ISBN-10、ISBN-13 和 ISSN 校验，支持空格与连字符
- 语义校验：缺失题名、非法 245 指示符、无效 ISBN/ISSN 和重复控制号诊断
- CLI：`inspect`、`validate`、`show`、`query`，其中 `validate` 同时执行结构与语义校验

## MoonBit API

```moonbit
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

```moonbit
pub(all) enum MarcField {
  ControlField(tag~ : String, value~ : String)
  DataField(
    tag~ : String,
    indicator1~ : Char,
    indicator2~ : Char,
    subfields~ : Array[Subfield],
  )
}

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
- 常用书目字段快捷查询
- ISBN-10、ISBN-13 与 ISSN 校验
- `245$a` 查询表达式解析
- 题名、指示符、标识符和重复控制号语义校验

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
identifiers/  ISBN 与 ISSN 校验
query/        MARC 子字段查询表达式
validation/   书目语义校验和诊断
cmd/main/     CLI
```

## 路线图

1. ISO 2709 序列化与 round-trip 测试
2. 扩展 MARC 21 字段与子字段规则库
3. JSON、MARCXML、CSV 转换
4. 隐私扫描、规则驱动脱敏和审计报告
5. 记录语义 Diff 与数据集统计
6. 浏览器本地 Wasm 查看器

## 隐私说明

MARC 数据可能包含采购备注、馆藏位置、本地 9XX 字段、内部 URL、电子邮箱、电话号码或其他个人信息。未来的隐私扫描和脱敏功能只能作为辅助工具使用：

> MoonMARC 只能提供技术层面的辅助检测，不能保证识别全部个人信息，正式公开数据前仍需人工审核。

## 许可证

Apache-2.0，见 [LICENSE](LICENSE)。
