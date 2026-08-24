///|
fn sample_record() -> @record.MarcRecord {
  {
    leader: @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap(),
    fields: [
      @record.MarcField::ControlField(tag="001", value="id-1"),
      @record.MarcField::DataField(tag="245", indicator1='1', indicator2='0', subfields=[
        @record.Subfield::{ code: 'a', value: "A & B <C>" },
        @record.Subfield::{ code: 'c', value: "作者 \"甲\"" },
      ]),
    ],
  }
}

///|
test "MARCXML record round trip escapes XML text" {
  let record = sample_record()
  let xml = record_to_xml(record)
  assert_true(xml.contains("<controlfield tag=\"001\">id-1</controlfield>"))
  assert_true(xml.contains("A &amp; B &lt;C&gt;"))
  assert_true(xml.contains("作者 &quot;甲&quot;"))
  assert_eq(record_from_xml(xml), Ok(record))
}

///|
test "MARCXML collection round trip" {
  let records = [sample_record(), sample_record()]
  let xml = records_to_xml(records)
  match records_from_xml(xml) {
    Err(error) => fail(error.to_string())
    Ok(value) => assert_eq(value, records)
  }
}

///|
test "MARCXML rejects malformed record" {
  match record_from_xml("<record><leader>bad</leader></record>") {
    Ok(_) => fail("expected invalid leader")
    Err(InvalidLeader(_)) => ()
    Err(error) => fail(error.to_string())
  }
}

///|
test "MARCXML rejects invalid subfield code" {
  let xml = "<record><leader>00000nam a2200000 i 4500</leader>" +
    "<datafield tag=\"245\" ind1=\"1\" ind2=\"0\">" +
    "<subfield code=\"title\">bad</subfield></datafield></record>"
  match record_from_xml(xml) {
    Ok(_) => fail("expected invalid subfield")
    Err(InvalidSubfield(_)) => ()
    Err(error) => fail(error.to_string())
  }
}
