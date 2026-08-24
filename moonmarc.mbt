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

///|
/// Convert one MARC 21 record to MARCXML.
pub fn record_to_xml(record : @record.MarcRecord) -> String {
  @marcxml.record_to_xml(record)
}

///|
/// Convert multiple MARC 21 records to a MARCXML collection.
pub fn records_to_xml(records : Array[@record.MarcRecord]) -> String {
  @marcxml.records_to_xml(records)
}

///|
/// Parse one MARCXML record.
pub fn record_from_xml(
  text : String,
) -> Result[@record.MarcRecord, @marcxml.MarcXmlError] {
  @marcxml.record_from_xml(text)
}

///|
/// Parse a MARCXML record or collection.
pub fn records_from_xml(
  text : String,
) -> Result[Array[@record.MarcRecord], @marcxml.MarcXmlError] {
  @marcxml.records_from_xml(text)
}

///|
/// Scan records for common privacy-sensitive values.
pub fn privacy_scan(
  records : Array[@record.MarcRecord],
) -> @privacy.PrivacyReport {
  @privacy.scan(records)
}

///|
/// Redact local fields and/or mask email-like values.
pub fn redact_records(
  records : Array[@record.MarcRecord],
  drop_9xx? : Bool,
  mask_email? : Bool,
) -> Array[@record.MarcRecord] {
  @privacy.redact(records, drop_9xx?, mask_email?)
}

///|
/// Calculate dataset coverage and field frequency statistics.
pub fn dataset_stats(
  results : Array[Result[@record.MarcRecord, @record.RecordError]],
) -> @stats.DatasetStats {
  @stats.analyze(results)
}
