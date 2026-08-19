test "bounded reader decodes decimal and ASCII fields" {
  let reader = Reader::new(ascii("00123001"))
  match reader {
    Err(error) => fail(error.to_string())
    Ok(reader) => {
      assert_eq(reader.read_decimal(5), Ok(123))
      assert_eq(reader.read_ascii(3), Ok("001"))
      assert_eq(reader.remaining(), 0)
    }
  }
}

///|
test "bounded reader reports truncation" {
  let reader = Reader::new(ascii("12"))
  match reader {
    Err(error) => fail(error.to_string())
    Ok(reader) =>
      match reader.read_bytes(3) {
        Ok(_) => fail("expected a truncation error")
        Err(Truncated(offset, need, available)) => {
          assert_eq(offset, 0)
          assert_eq(need, 3)
          assert_eq(available, 2)
        }
        Err(error) => fail(error.to_string())
      }
  }
}

///|
test "UTF-8 decoder accepts multibyte bibliographic text" {
  let bytes = @utf8.encode("MoonBit 编程实践")
  assert_eq(decode_utf8(bytes), Ok("MoonBit 编程实践"))
}
