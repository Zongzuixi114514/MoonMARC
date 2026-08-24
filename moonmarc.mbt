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

///|
/// Serialize one MARC 21 record to ISO 2709 bytes.
pub fn serialize_record(
  record : @record.MarcRecord,
) -> Result[Bytes, @iso2709.SerializeError] {
  @iso2709.serialize_record(record)
}

///|
/// Serialize multiple MARC 21 records to one ISO 2709 stream.
pub fn serialize_records(
  records : Array[@record.MarcRecord],
) -> Result[Bytes, @iso2709.SerializeError] {
  @iso2709.serialize_records(records)
}
