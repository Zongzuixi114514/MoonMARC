# 格式说明

## ISO 2709 / MARC

解析器支持标准 MARC 21 的 24 字节 Leader、Directory、控制字段 `001-009`、数据字段、Indicator、子字段分隔符和多记录流。解析失败会返回记录级错误，不会把越界字段静默解释成有效数据。

序列化时会重算记录长度、Directory 和 Base Address；因此 `parse -> serialize -> parse` 比较字段结构和 Leader 业务位置，而不是要求长度字段保持原始文本。

## JSON

JSON 使用 MoonMARC 自有的结构化交换形状：记录包含 `leader` 和 `fields`；控制字段使用 `value`，数据字段使用 `indicators` 和 `subfields`。可以表示单条记录或记录数组。

## MARCXML

MARCXML 支持核心 `record` 和 `collection` 元素、`leader`、`controlfield`、`datafield` 与 `subfield`。文本和属性值会转义 `&`、`<`、`>`、`"`、`'`。

这是轻量转换器，不是完整 XML 标准解析器，不承诺任意命名空间、复杂混合内容、XML Schema 验证或全部 MARCXML 扩展语义。
