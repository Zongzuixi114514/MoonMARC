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

///|
/// Convert one MARC 21 record to the MoonMARC JSON interchange shape.
pub fn record_to_json(record : @record.MarcRecord) -> Json {
  @marcjson.record_to_json(record)
}

///|
/// Convert multiple MARC 21 records to a JSON array.
pub fn records_to_json(records : Array[@record.MarcRecord]) -> Json {
  @marcjson.records_to_json(records)
}

///|
/// Render one MARC 21 record as JSON text.
pub fn record_to_json_text(
  record : @record.MarcRecord,
  indent? : Int,
) -> String {
  match indent {
    None => @marcjson.record_to_json_text(record)
    Some(width) => @marcjson.record_to_json_text(record, indent=width)
  }
}

///|
/// Render multiple MARC 21 records as a JSON array text.
pub fn records_to_json_text(
  records : Array[@record.MarcRecord],
  indent? : Int,
) -> String {
  match indent {
    None => @marcjson.records_to_json_text(records)
    Some(width) => @marcjson.records_to_json_text(records, indent=width)
  }
}

///|
/// Convert a JSON value to one structured MARC 21 record.
pub fn record_from_json(
  value : Json,
) -> Result[@record.MarcRecord, @marcjson.JsonConversionError] {
  @marcjson.record_from_json(value)
}

///|
/// Convert a JSON array to structured MARC 21 records.
pub fn records_from_json(
  value : Json,
) -> Result[Array[@record.MarcRecord], @marcjson.JsonConversionError] {
  @marcjson.records_from_json(value)
}

///|
/// Parse JSON text and convert it to one structured MARC 21 record.
pub fn record_from_json_text(
  text : String,
) -> Result[@record.MarcRecord, @marcjson.JsonConversionError] {
  @marcjson.record_from_json_text(text)
}

///|
/// Parse JSON text containing an array of MARC 21 records.
pub fn records_from_json_text(
  text : String,
) -> Result[Array[@record.MarcRecord], @marcjson.JsonConversionError] {
  @marcjson.records_from_json_text(text)
}
