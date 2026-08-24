///|
fn stats_sample() -> @record.MarcRecord {
  {
    leader: @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap(),
    fields: [
      @record.MarcField::ControlField(tag="001", value="id-1"),
      @record.MarcField::DataField(tag="100", indicator1='1', indicator2=' ', subfields=[
        @record.Subfield::{ code: 'a', value: "Author" },
      ]),
      @record.MarcField::DataField(tag="245", indicator1='1', indicator2='0', subfields=[
        @record.Subfield::{ code: 'a', value: "Title" },
      ]),
    ],
  }
}

///|
test "dataset statistics count coverage and fields" {
  let valid = stats_sample()
  let results : Array[Result[@record.MarcRecord, @record.RecordError]] = [
    Ok(valid),
    Err(@record.FieldTerminatorMissing("245")),
  ]
  let summary = @stats.analyze(results)
  assert_eq(summary.records, 2)
  assert_eq(summary.valid, 1)
  assert_eq(summary.errors, 1)
  assert_eq(summary.title_coverage, 100)
  assert_eq(summary.author_coverage, 100)
  assert_eq(summary.isbn_coverage, 0)
  assert_eq(summary.field_counts[0], { tag: "001", count: 1 })
}
