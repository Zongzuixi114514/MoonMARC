///|
test "parse MARC subfield query" {
  assert_eq(parse("245$a"), Ok(Query::{ tag: "245", code: 'a' }))
  assert_eq(parse("650$x"), Ok(Query::{ tag: "650", code: 'x' }))
}

///|
test "reject malformed MARC subfield queries" {
  assert_true(parse("245a") is Err(InvalidLength(_)))
  assert_true(parse("245-a") is Err(MissingSeparator))
  assert_true(parse("24!$a") is Err(InvalidTag(_)))
  assert_true(parse("245$!") is Err(InvalidCode('!')))
}
