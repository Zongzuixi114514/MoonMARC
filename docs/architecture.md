# MoonMARC 架构

MoonMARC 按数据模型、格式适配和命令行入口分层：

- `record/` 定义 `MarcRecord`、`MarcField` 和 `Subfield`。
- `leader/`、`directory/`、`binary/` 提供 ISO 2709 的底层校验和读取能力。
- `iso2709/` 负责 `.mrc` 记录流解析与序列化。
- `formats/marcjson/` 和 `formats/marcxml/` 负责结构化格式转换。
- 根包 `moonmarc.mbt` 提供稳定 facade，避免调用方依赖格式包内部布局。
- `privacy/` 和 `stats/` 只消费结构化记录，不改变格式解析器。
- `cmd/main/` 负责文件读写、参数解析和人类可读输出。

格式转换的核心不变式是字段顺序、重复字段、Leader 业务位置、指示符和子字段顺序保持一致。ISO 2709 序列化会重新计算记录长度、Directory 和 Base Address，这是标准布局要求。
