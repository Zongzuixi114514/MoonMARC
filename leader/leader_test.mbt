///|
test "parse MARC 21 leader and entry map" {
  let leader = @leader.parse(@binary.ascii("00097nam a2200049 i 4500"))
  match leader {
    Err(error) => fail(error.to_string())
    Ok(value) => {
      assert_eq(value.record_length(), Ok(97))
      assert_eq(value.status(), 'n')
      assert_eq(value.record_type(), 'a')
      assert_eq(value.bibliographic_level(), 'm')
      assert_eq(value.base_address(), Ok(49))
      assert_eq(value.entry_map(), Ok((4, 5, 0)))
    }
  }
}

///|
test "leader rejects malformed entry map" {
  let leader = @leader.parse(@binary.ascii("00097nam a2200049 i 4A00")).unwrap()
  match leader.entry_map() {
    Ok(_) => fail("expected invalid entry map")
    Err(InvalidEntryMap(_)) => ()
    Err(error) => fail(error.to_string())
  }
}
