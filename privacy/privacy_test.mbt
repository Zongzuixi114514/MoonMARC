///|
fn privacy_sample() -> @record.MarcRecord {
  {
    leader: @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap(),
    fields: [
      @record.MarcField::ControlField(tag="001", value="id-1"),
      @record.MarcField::DataField(tag="245", indicator1='1', indicator2='0', subfields=[
        @record.Subfield::{ code: 'a', value: "A title" },
        @record.Subfield::{ code: 'e', value: "owner@example.org" },
      ]),
      @record.MarcField::DataField(tag="900", indicator1=' ', indicator2=' ', subfields=[
        @record.Subfield::{ code: 'a', value: "010-1234-5678" },
      ]),
    ],
  }
}

///|
test "privacy scan detects common sensitive values" {
  let report = @privacy.scan([privacy_sample()])
  assert_eq(report.records, 1)
  assert_eq(report.local_fields, 1)
  assert_eq(report.email_values, 1)
  assert_eq(report.phone_values, 1)
  assert_true(report.manual_review_required)
}

///|
test "privacy redact drops local fields and masks email" {
  let redacted = @privacy.redact(
    [privacy_sample()],
    drop_9xx=true,
    mask_email=true,
  )
  assert_eq(redacted.length(), 1)
  assert_eq(redacted[0].fields_by_tag("900").length(), 0)
  assert_eq(redacted[0].first_subfield("245", 'e'), Some("***@example.org"))
}
