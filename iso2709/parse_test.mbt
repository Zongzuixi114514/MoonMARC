///|
fn sample_record() -> Bytes {
  let control = @binary.concat([
    @binary.ascii("book-001"),
    Bytes::from_array([0x1E]),
  ])
  let data = @binary.concat([
    @binary.ascii("10"),
    Bytes::from_array([0x1F]),
    @binary.ascii("a"),
    @utf8.encode("MoonBit 编程实践"),
    Bytes::from_array([0x1E]),
  ])
  let directory = @binary.ascii(
    "001" +
    "\{control.length()}".pad_start(4, '0') +
    "00000" +
    "245" +
    "\{data.length()}".pad_start(4, '0') +
    "\{control.length()}".pad_start(5, '0'),
  )
  let base_address = 24 + directory.length() + 1
  let total_length = base_address + control.length() + data.length() + 1
  let leader = "\{total_length}".pad_start(5, '0') +
    "nam a22" +
    "\{base_address}".pad_start(5, '0') +
    " i 4500"
  @binary.concat([
    @binary.ascii(leader),
    directory,
    Bytes::from_array([0x1E]),
    control,
    data,
    Bytes::from_array([0x1D]),
  ])
}

///|
test "parse a MARC record and query its title" {
  let result = parse_record(sample_record())
  match result {
    Err(error) => fail(error.to_string())
    Ok(record) => {
      assert_eq(record.control_number(), Some("book-001"))
      assert_eq(record.title(), Some("MoonBit 编程实践"))
      assert_eq(record.fields().length(), 2)
    }
  }
}

///|
test "parse a concatenated record stream" {
  let one = sample_record()
  let results = parse_records(@binary.concat([one, one]))
  assert_eq(results.length(), 2)
  for result in results {
    match result {
      Ok(record) => assert_eq(record.control_number(), Some("book-001"))
      Err(error) => fail(error.to_string())
    }
  }
}

///|
fn replace_byte(raw : Bytes, offset : Int, value : Int) -> Bytes {
  let data = raw.to_fixedarray()
  data[offset] = value.to_byte()
  Bytes::from_array(data)
}

///|
fn replace_ascii(raw : Bytes, offset : Int, value : String) -> Bytes {
  let data = raw.to_fixedarray()
  let mut index = 0
  for char in value {
    data[offset + index] = char.to_int().to_byte()
    index = index + 1
  }
  Bytes::from_array(data)
}

///|
test "reject truncated records" {
  match parse_record(Bytes::make(10, 0)) {
    Err(InvalidLength(25, 10)) => ()
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected truncated record")
  }
}

///|
test "reject leader record length mismatch" {
  let raw = replace_ascii(sample_record(), 0, "00001")
  match parse_record(raw) {
    Err(InvalidLength(1, actual)) => assert_eq(actual, sample_record().length())
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected a length mismatch")
  }
}

///|
test "reject a directory without its terminator" {
  let raw = replace_byte(sample_record(), 48, 0x20)
  match parse_record(raw) {
    Err(Directory(MissingTerminator)) => ()
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected a directory terminator error")
  }
}

///|
test "reject a field outside the record boundary" {
  let raw = replace_ascii(sample_record(), 43, "99999")
  match parse_record(raw) {
    Err(FieldOutsideRecord("245")) => ()
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected an out-of-bounds field error")
  }
}

///|
test "reject a field without its terminator" {
  let raw = replace_byte(sample_record(), 57, 0x20)
  match parse_record(raw) {
    Err(FieldTerminatorMissing("001")) => ()
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected a field terminator error")
  }
}

///|
test "reject a record without its terminator" {
  let raw = replace_byte(sample_record(), sample_record().length() - 1, 0x20)
  match parse_record(raw) {
    Err(FieldTerminatorMissing("record")) => ()
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected a record terminator error")
  }
}

///|
test "reject invalid UTF-8 in a data field" {
  let raw = replace_byte(sample_record(), 62, 0xFF)
  match parse_record(raw) {
    Err(InvalidUtf8("245")) => ()
    Err(error) => fail(error.to_string())
    Ok(_) => fail("expected an UTF-8 error")
  }
}

///|
fn parsed_sample() -> @record.MarcRecord {
  parse_record(sample_record()).unwrap()
}

///|
test "serialize a parsed record and preserve its field structure" {
  let original = parsed_sample()
  let raw = match serialize_record(original) {
    Err(error) => fail(error.to_string())
    Ok(value) => value
  }
  assert_eq(raw[raw.length() - 1], 0x1D)
  match parse_record(raw) {
    Err(error) => fail(error.to_string())
    Ok(decoded) => {
      assert_eq(decoded.fields(), original.fields())
      assert_eq(decoded.leader().record_length(), Ok(raw.length()))
      assert_eq(decoded.leader().base_address(), Ok(49))
      assert_eq(decoded.leader().entry_map(), Ok((4, 5, 0)))
    }
  }
}

///|
test "serialize a concatenated record stream" {
  let record = parsed_sample()
  let raw = match serialize_records([record, record]) {
    Err(error) => fail(error.to_string())
    Ok(value) => value
  }
  let results = parse_records(raw)
  assert_eq(results.length(), 2)
  for result in results {
    match result {
      Err(error) => fail(error.to_string())
      Ok(decoded) => assert_eq(decoded.title(), Some("MoonBit 编程实践"))
    }
  }
}

///|
test "reject a data field using a control tag during serialization" {
  let leader = @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap()
  let record : @record.MarcRecord = {
    leader,
    fields: [
      @record.MarcField::DataField(tag="001", indicator1=' ', indicator2=' ', subfields=[]),
    ],
  }
  assert_true(serialize_record(record) is Err(ControlFieldTag("001")))
}

///|
test "reject delimiters in serialized field content" {
  let leader = @leader.parse(@binary.ascii("00000nam a2200000 i 4500")).unwrap()
  let record : @record.MarcRecord = {
    leader,
    fields: [
      @record.MarcField::ControlField(tag="001", value="bad\u{001E}value"),
    ],
  }
  assert_true(serialize_record(record) is Err(InvalidFieldValue("001")))
}
