# MoonMARC 验收步骤

## 基础检查

```powershell
moon fmt --check
moon check --target all
moon test
```

## CLI 闭环

```powershell
moon run cmd/main -- inspect fixtures/valid-single.mrc
moon run cmd/main -- validate fixtures/valid-single.mrc
moon run cmd/main -- show fixtures/valid-single.mrc --record 1
moon run cmd/main -- query fixtures/valid-single.mrc '245$a'
moon run cmd/main -- convert fixtures/valid-single.mrc --format json --pretty
moon run cmd/main -- convert fixtures/sample.json --format mrc --output examples/from-json.mrc
moon run cmd/main -- convert fixtures/valid-single.mrc --format marcxml --output examples/from-mrc.xml
moon run cmd/main -- convert fixtures/sample.xml --format mrc --output examples/from-xml.mrc
moon run cmd/main -- privacy fixtures/valid-single.mrc
moon run cmd/main -- stats fixtures/valid-single.mrc
```

解析 `examples/from-json.mrc` 和 `examples/from-xml.mrc` 后，应与原记录保持字段、控制字段、指示符和子字段顺序一致。ISO 2709 的记录长度和 Base Address 允许由序列化器按输出内容重算。

## 异常输入

用 `inspect` 或 `validate` 运行 `fixtures/malformed-*.mrc`，应输出记录级错误而不是崩溃。`formats/marcxml/xml_test.mbt` 覆盖了错误 Leader、错误子字段代码和 XML 特殊字符。

## 隐私限制

隐私扫描只提供辅助提示。公开数据前必须人工审核，不得把“没有检测到匹配项”当作隐私安全保证。
