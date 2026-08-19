///|
fn is_control_tag(tag : String) -> Bool {
  tag >= "001" && tag <= "009"
}

///|
fn ascii_char(raw : Bytes, offset : Int) -> Char? {
  let value = raw[offset].to_int()
  if value > 0x7F {
    None
  } else {
    Some(value.unsafe_to_char())
  }
}

///|
fn decode_field(
  raw : Bytes,
  offset : Int,
  entry : @directory.DirectoryEntry,
) -> Result[@record.MarcField, @record.RecordError] {
  if entry.length < 1 || offset < 0 || offset + entry.length > raw.length() {
    return Err(@record.FieldOutsideRecord(entry.tag))
  }
  let end = offset + entry.length
  if raw[end - 1].to_int() != 0x1E {
    return Err(@record.FieldTerminatorMissing(entry.tag))
  }
  let content_length = entry.length - 1
  if is_control_tag(entry.tag) {
    if content_length > 0 && raw[offset].to_int() == 0x1F {
      return Err(@record.InvalidControlField(entry.tag))
    }
    let value = match @binary.decode_utf8(raw, offset~, length=content_length) {
      Err(_) => return Err(@record.InvalidUtf8(entry.tag))
      Ok(value) => value
    }
    return Ok(@record.MarcField::ControlField(tag=entry.tag, value~))
  }
  if content_length < 2 {
    return Err(@record.InvalidDataField(entry.tag))
  }
  let indicator1 = match ascii_char(raw, offset) {
    None => return Err(@record.InvalidDataField(entry.tag))
    Some(value) => value
  }
  let indicator2 = match ascii_char(raw, offset + 1) {
    None => return Err(@record.InvalidDataField(entry.tag))
    Some(value) => value
  }
  let subfields : Array[@record.Subfield] = []
  let mut cursor = offset + 2
  let content_end = end - 1
  while cursor < content_end {
    if raw[cursor].to_int() != 0x1F || cursor + 1 >= content_end {
      return Err(@record.InvalidSubfield(entry.tag))
    }
    let code = match ascii_char(raw, cursor + 1) {
      None => return Err(@record.InvalidSubfield(entry.tag))
      Some(value) => value
    }
    let value_start = cursor + 2
    let mut value_end = value_start
    while value_end < content_end && raw[value_end].to_int() != 0x1F {
      value_end = value_end + 1
    }
    let value = match
      @binary.decode_utf8(
        raw,
        offset=value_start,
        length=value_end - value_start,
      ) {
      Err(_) => return Err(@record.InvalidUtf8(entry.tag))
      Ok(value) => value
    }
    subfields.push({ code, value })
    cursor = value_end
  }
  Ok(
    @record.MarcField::DataField(
      tag=entry.tag,
      indicator1~,
      indicator2~,
      subfields~,
    ),
  )
}

///|
/// Parse one complete ISO 2709 / MARC 21 record.
pub fn parse_record(
  raw : Bytes,
) -> Result[@record.MarcRecord, @record.RecordError] {
  if raw.length() < 25 {
    return Err(@record.InvalidLength(25, raw.length()))
  }
  if raw[raw.length() - 1].to_int() != 0x1D {
    return Err(@record.FieldTerminatorMissing("record"))
  }
  let leader = match @leader.parse(@binary.slice(raw, 0, 24)) {
    Err(error) => return Err(@record.Leader(error))
    Ok(value) => value
  }
  let expected_length = match leader.record_length() {
    Err(error) => return Err(@record.Leader(error))
    Ok(value) => value
  }
  if expected_length != raw.length() {
    return Err(@record.InvalidLength(expected_length, raw.length()))
  }
  let base_address = match leader.base_address() {
    Err(error) => return Err(@record.Leader(error))
    Ok(value) => value
  }
  if base_address <= 24 || base_address >= raw.length() {
    return Err(@record.FieldOutsideRecord("directory"))
  }
  let entries = match @directory.parse(raw, leader) {
    Err(error) => return Err(@record.Directory(error))
    Ok(value) => value
  }
  let fields : Array[@record.MarcField] = []
  for entry in entries {
    let offset = base_address + entry.start
    fields.push(
      match decode_field(raw, offset, entry) {
        Err(error) => return Err(error)
        Ok(field) => field
      },
    )
  }
  Ok({ leader, fields })
}

///|
/// Parse a concatenated stream of complete records.
pub fn parse_records(
  raw : Bytes,
) -> Array[Result[@record.MarcRecord, @record.RecordError]] {
  let records : Array[Result[@record.MarcRecord, @record.RecordError]] = []
  let mut offset = 0
  while offset < raw.length() {
    if raw.length() - offset < 24 {
      records.push(Err(@record.InvalidLength(24, raw.length() - offset)))
      break
    }
    let leader_bytes = @binary.slice(raw, offset, offset + 24)
    let leader = match @leader.parse(leader_bytes) {
      Err(error) => {
        records.push(Err(@record.Leader(error)))
        break
      }
      Ok(value) => value
    }
    let length = match leader.record_length() {
      Err(error) => {
        records.push(Err(@record.Leader(error)))
        break
      }
      Ok(value) => value
    }
    if length <= 0 || offset + length > raw.length() {
      records.push(Err(@record.InvalidLength(length, raw.length() - offset)))
      break
    }
    records.push(parse_record(@binary.slice(raw, offset, offset + length)))
    offset = offset + length
  }
  records
}
