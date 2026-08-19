///|
test "validate ISBN-10 identifiers" {
  assert_true(is_valid_isbn10("0-306-40615-2"))
  assert_true(is_valid_isbn10("0-8044-2957-X"))
  assert_false(is_valid_isbn10("0-306-40615-3"))
  assert_false(is_valid_isbn10("030640615"))
}

///|
test "validate ISBN-13 identifiers" {
  assert_true(is_valid_isbn13("978-0-306-40615-7"))
  assert_true(is_valid_isbn("978 7 300 00000 8"))
  assert_false(is_valid_isbn13("978-0-306-40615-8"))
  assert_false(is_valid_isbn13("978-0-306-4061X-7"))
}

///|
test "validate ISSN identifiers" {
  assert_true(is_valid_issn("0378-5955"))
  assert_true(is_valid_issn("2434-561X"))
  assert_false(is_valid_issn("0378-5954"))
  assert_false(is_valid_issn("0378595"))
}
