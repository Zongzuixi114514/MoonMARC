///|
test "parse standard MARC directory" {
  let raw = @binary.concat([
    @binary.ascii("00049nam a2200049 i 4500"),
    @binary.ascii("001000900000245002500009"),
    Bytes::from_array([0x1E]),
  ])
  let leader = @leader.parse(@binary.slice(raw, 0, 24)).unwrap()
  let entries = parse(raw, leader).unwrap()
  assert_eq(entries.length(), 2)
  assert_eq(entries[0], { tag: "001", length: 9, start: 0 })
  assert_eq(entries[1], { tag: "245", length: 25, start: 9 })
}
