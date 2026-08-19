///|
/// Small public facade for the first MoonMARC parsing APIs.
pub fn parse_record(
  raw : Bytes,
) -> Result[@record.MarcRecord, @record.RecordError] {
  @iso2709.parse_record(raw)
}

///|
pub fn parse_records(
  raw : Bytes,
) -> Array[Result[@record.MarcRecord, @record.RecordError]] {
  @iso2709.parse_records(raw)
}
