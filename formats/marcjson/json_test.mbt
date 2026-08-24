///|
fn sample_record() -> @record.MarcRecord {
  let leader = @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap()
  {
    leader,
    fields: [
      @record.MarcField::ControlField(tag="001", value="book-0001"),
      @record.MarcField::DataField(tag="245", indicator1='1', indicator2='0', subfields=[
        { code: 'a', value: "MoonBit 编程实践" },
        { code: 'c', value: "示例作者" },
      ]),
      @record.MarcField::DataField(tag="650", indicator1=' ', indicator2='0', subfields=[
        { code: 'a', value: "Functional programming" },
      ]),
    ],
  }
}

///|
test "convert a MARC record to JSON and back" {
  let original = sample_record()
  assert_eq(record_from_json(record_to_json(original)), Ok(original))
}

///|
test "convert a MARC record to indented JSON text and back" {
  let original = sample_record()
  let text = record_to_json_text(original, indent=2)
  assert_true(text.contains("\"leader\""))
  assert_true(text.contains("MoonBit 编程实践"))
  assert_eq(record_from_json_text(text), Ok(original))
}

///|
test "preserve repeated data fields in the JSON array shape" {
  let original = sample_record()
  let decoded = records_from_json(records_to_json([original, original]))
  assert_eq(decoded, Ok([original, original]))
}

///|
test "reject malformed JSON text" {
  assert_true(record_from_json_text("{") is Err(InvalidJson(_)))
}

///|
test "reject JSON records without a leader" {
  assert_true(
    record_from_json_text("{\"fields\":[]}") is Err(MissingField("leader")),
  )
}

///|
test "reject data fields with control tags" {
  let source = "{\"leader\":\"00000nam a2200000 i 4500\",\"fields\":[{\"tag\":\"001\",\"indicators\":[\" \",\" \"],\"subfields\":[]}]}"
  assert_true(
    record_from_json_text(source) is Err(InvalidValue("control field")),
  )
}

///|
test "reject control values with data tags" {
  let source = "{\"leader\":\"00000nam a2200000 i 4500\",\"fields\":[{\"tag\":\"245\",\"value\":\"not a control field\"}]}"
  assert_true(record_from_json_text(source) is Err(InvalidValue("value")))
}

///|
test "reject multi-character indicator values" {
  let source = "{\"leader\":\"00000nam a2200000 i 4500\",\"fields\":[{\"tag\":\"245\",\"indicators\":[\"10\",\"0\"],\"subfields\":[]}]}"
  assert_true(
    record_from_json_text(source) is Err(InvalidValue("indicators[0]")),
  )
}
