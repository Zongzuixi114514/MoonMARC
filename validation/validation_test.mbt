///|
fn test_record(
  control_number : String,
  isbn : String,
  title_subfields : Array[@record.Subfield],
) -> @record.MarcRecord {
  let leader = @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap()
  {
    leader,
    fields: [
      @record.MarcField::ControlField(tag="001", value=control_number),
      @record.MarcField::DataField(tag="020", indicator1=' ', indicator2=' ', subfields=[
        @record.Subfield::{ code: 'a', value: isbn },
      ]),
      @record.MarcField::DataField(
        tag="245",
        indicator1='1',
        indicator2='0',
        subfields=title_subfields,
      ),
    ],
  }
}

///|
test "validate title and identifier rules" {
  let valid = test_record("book-1", "978-0-306-40615-7 (hardcover)", [
    @record.Subfield::{ code: 'a', value: "MoonBit" },
  ])
  assert_eq(validate_record(valid).length(), 0)
  let invalid = test_record("book-2", "978-0-306-40615-8", [
    @record.Subfield::{ code: 'b', value: "Subtitle only" },
  ])
  let diagnostics = validate_record(invalid, record_index=1)
  assert_eq(diagnostics.length(), 2)
  assert_eq(diagnostics[0].code, "BIB245_A")
  assert_eq(diagnostics[1].code, "ISBN001")
}

///|
test "detect duplicate control numbers" {
  let one = test_record("same-id", "978-0-306-40615-7", [
    @record.Subfield::{ code: 'a', value: "One" },
  ])
  let two = test_record("same-id", "978-0-306-40615-7", [
    @record.Subfield::{ code: 'a', value: "Two" },
  ])
  let diagnostics = validate_unique_control_numbers([one, two])
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].code, "BIB001_DUP")
  assert_eq(diagnostics[0].record_index, 1)
}
