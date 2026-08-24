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
test "round-trip a MARC record through MARCXML and ISO 2709" {
  let original = record_from_json_text(sample_json_record_text()).unwrap()
  let xml = record_to_xml(original)
  let from_xml = match record_from_xml(xml) {
    Err(error) => fail(error.to_string())
    Ok(record) => record
  }
  assert_eq(from_xml, original)
  let encoded = match serialize_record(from_xml) {
    Err(error) => fail(error.to_string())
    Ok(bytes) => bytes
  }
  match parse_record(encoded) {
    Err(error) => fail(error.to_string())
    Ok(decoded) => {
      assert_eq(decoded.fields(), original.fields())
      assert_eq(decoded.leader().status(), original.leader().status())
      assert_eq(decoded.leader().record_type(), original.leader().record_type())
      assert_eq(
        decoded.leader().bibliographic_level(),
        original.leader().bibliographic_level(),
      )
      assert_eq(decoded.leader().entry_map(), Ok((4, 5, 0)))
    }
  }
}

///|
test "round-trip a MARC record collection through MARCXML" {
  let original = record_from_json_text(sample_json_record_text()).unwrap()
  let xml = records_to_xml([original, original])
  match records_from_xml(xml) {
    Err(error) => fail(error.to_string())
    Ok(records) => assert_eq(records, [original, original])
  }
}
