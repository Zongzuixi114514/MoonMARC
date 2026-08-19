///|
test "query common bibliographic subfields" {
  let leader = @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap()
  let record : MarcRecord = {
    leader,
    fields: [
      MarcField::ControlField(tag="001", value="book-1"),
      MarcField::DataField(tag="020", indicator1=' ', indicator2=' ', subfields=[
        Subfield::{ code: 'a', value: "978-1" },
      ]),
      MarcField::DataField(tag="245", indicator1='1', indicator2='0', subfields=[
        Subfield::{ code: 'a', value: "MoonBit" },
        Subfield::{ code: 'b', value: "编程实践" },
      ]),
      MarcField::DataField(tag="650", indicator1=' ', indicator2='0', subfields=[
        Subfield::{ code: 'a', value: "编程语言" },
      ]),
    ],
  }
  assert_eq(record.isbn_list(), ["978-1"])
  assert_eq(record.title(), Some("MoonBit"))
  assert_eq(record.subtitle(), Some("编程实践"))
  assert_eq(record.subjects(), ["编程语言"])
}
