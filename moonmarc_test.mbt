// Blackbox tests run against the package's public API. Use `@moonmarc` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
fn sample_json_record_text() -> String {
  "{\"leader\":\"00000nam a2200000 i 4500\",\"fields\":[{\"tag\":\"001\",\"value\":\"book-001\"},{\"tag\":\"245\",\"indicators\":[\"1\",\"0\"],\"subfields\":[{\"code\":\"a\",\"value\":\"MoonBit 编程实践\"}]}]}"
}

///|
test "round-trip JSON through ISO 2709 serialization" {
  let original = record_from_json_text(sample_json_record_text()).unwrap()
  let json_text = record_to_json_text(original, indent=2)
  let from_json = match record_from_json_text(json_text) {
    Err(error) => fail(error.to_string())
    Ok(record) => record
  }
  let encoded = match serialize_record(from_json) {
    Err(error) => fail(error.to_string())
    Ok(bytes) => bytes
  }
  match parse_record(encoded) {
    Err(error) => fail(error.to_string())
    Ok(decoded) => {
      assert_eq(decoded.fields(), original.fields())
      assert_eq(decoded.title(), Some("MoonBit 编程实践"))
      assert_eq(decoded.leader().record_length(), Ok(encoded.length()))
    }
  }
}

///|
test "round-trip a JSON record array through an ISO 2709 stream" {
  let original = record_from_json_text(sample_json_record_text()).unwrap()
  let json_text = records_to_json_text([original, original])
  let records = match records_from_json_text(json_text) {
    Err(error) => fail(error.to_string())
    Ok(value) => value
  }
  assert_eq(records, [original, original])
  let encoded = match serialize_records(records) {
    Err(error) => fail(error.to_string())
    Ok(bytes) => bytes
  }
  let decoded = parse_records(encoded)
  assert_eq(decoded.length(), 2)
  for result in decoded {
    match result {
      Err(error) => fail(error.to_string())
      Ok(record) => assert_eq(record.control_number(), Some("book-001"))
    }
  }
}
