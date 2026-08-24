///|
fn is_control_tag_for_serialization(tag : String) -> Bool {
  tag >= "001" && tag <= "009"
}

///|
fn valid_ascii_char(value : Char) -> Bool {
  value.to_int() <= 0x7F
}

///|
fn valid_tag(tag : String) -> Bool {
  if tag.length() != 3 {
    return false
  }
  for char in tag {
    if !valid_ascii_char(char) {
      return false
    }
  }
  true
}

///|
fn has_iso2709_delimiter(bytes : Bytes) -> Bool {
  for byte in bytes {
    let value = byte.to_int()
    if value == 0x1D || value == 0x1E || value == 0x1F {
      return true
    }
  }
  false
}

///|
fn ascii_number(value : Int, width : Int) -> String? {
  let text = value.to_string()
  if value < 0 || text.length() > width {
    None
  } else {
    Some(text.pad_start(width, '0'))
  }
}

///|
fn patch_ascii_range(raw : String, start : Int, value : String) -> String {
  let chars : Array[Char] = []
  for char in raw {
    chars.push(char)
  }
  let mut index = 0
  for char in value {
    chars[start + index] = char
    index = index + 1
  }
  String::from_array(chars)
}

///|
fn encode_field(
  field : @record.MarcField,
) -> Result[(String, Bytes), SerializeError] {
  match field {
    @record.MarcField::ControlField(tag~, value~) => {
      if !valid_tag(tag) {
        return Err(InvalidTag(tag))
      }
      if !is_control_tag_for_serialization(tag) {
        return Err(ControlFieldTag(tag))
      }
      let content = @utf8.encode(value)
      if has_iso2709_delimiter(content) {
        return Err(InvalidFieldValue(tag))
      }
      let field_bytes = @binary.concat([content, Bytes::from_array([0x1E])])
      if field_bytes.length() > 9999 {
        return Err(FieldTooLong(tag, field_bytes.length()))
      }
      Ok((tag, field_bytes))
    }
    @record.MarcField::DataField(tag~, indicator1~, indicator2~, subfields~) => {
      if !valid_tag(tag) {
        return Err(InvalidTag(tag))
      }
      if is_control_tag_for_serialization(tag) {
        return Err(ControlFieldTag(tag))
      }
      if !valid_ascii_char(indicator1) || !valid_ascii_char(indicator2) {
        return Err(InvalidIndicator(tag))
      }
      let pieces : Array[Bytes] = [
        @binary.ascii(indicator1.to_string() + indicator2.to_string()),
      ]
      for subfield in subfields {
        if !valid_ascii_char(subfield.code) ||
          subfield.code == '\u{1D}' ||
          subfield.code == '\u{1E}' ||
          subfield.code == '\u{1F}' {
          return Err(InvalidSubfieldCode(subfield.code))
        }
        let value = @utf8.encode(subfield.value)
        if has_iso2709_delimiter(value) {
          return Err(InvalidFieldValue(tag))
        }
        pieces.push(Bytes::from_array([0x1F]))
        pieces.push(@binary.ascii(subfield.code.to_string()))
        pieces.push(value)
      }
      let content = @binary.concat(pieces)
      let field_bytes = @binary.concat([content, Bytes::from_array([0x1E])])
      if field_bytes.length() > 9999 {
        return Err(FieldTooLong(tag, field_bytes.length()))
      }
      Ok((tag, field_bytes))
    }
  }
}

///|
/// Serialize one parsed MARC 21 record to ISO 2709 bytes.
pub fn serialize_record(
  record : @record.MarcRecord,
) -> Result[Bytes, SerializeError] {
  let encoded_fields : Array[(String, Bytes)] = []
  let mut variable_length = 0
  for field in record.fields() {
    let encoded = match encode_field(field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    encoded_fields.push(encoded)
    variable_length = variable_length + encoded.1.length()
  }
  let directory_length = encoded_fields.length() * 12
  let base_address = 24 + directory_length + 1
  let total_length = base_address + variable_length + 1
  if base_address > 99999 {
    return Err(DirectoryOverflow(base_address))
  }
  if total_length > 99999 {
    return Err(RecordTooLong(total_length))
  }
  let mut directory = ""
  let mut start = 0
  for encoded in encoded_fields {
    let length = match ascii_number(encoded.1.length(), 4) {
      None => return Err(FieldTooLong(encoded.0, encoded.1.length()))
      Some(value) => value
    }
    let offset = match ascii_number(start, 5) {
      None => return Err(DirectoryOverflow(start))
      Some(value) => value
    }
    directory = directory + encoded.0 + length + offset
    start = start + encoded.1.length()
  }
  let leader = record.leader().raw()
  let record_length = match ascii_number(total_length, 5) {
    None => return Err(RecordTooLong(total_length))
    Some(value) => value
  }
  let base = match ascii_number(base_address, 5) {
    None => return Err(DirectoryOverflow(base_address))
    Some(value) => value
  }
  // MoonMARC always emits standard MARC 21 directory entries: 3 + 4 + 5 + 0.
  let leader = patch_ascii_range(leader, 10, "22")
  let leader = patch_ascii_range(leader, 20, "4500")
  let leader = patch_ascii_range(leader, 0, record_length)
  let leader = patch_ascii_range(leader, 12, base)
  let parts : Array[Bytes] = [
    @binary.ascii(leader),
    @binary.ascii(directory),
    Bytes::from_array([0x1E]),
  ]
  for encoded in encoded_fields {
    parts.push(encoded.1)
  }
  parts.push(Bytes::from_array([0x1D]))
  Ok(@binary.concat(parts))
}

///|
/// Serialize multiple MARC records as one concatenated ISO 2709 stream.
pub fn serialize_records(
  records : Array[@record.MarcRecord],
) -> Result[Bytes, SerializeError] {
  let parts : Array[Bytes] = []
  for record in records {
    match serialize_record(record) {
      Err(error) => return Err(error)
      Ok(value) => parts.push(value)
    }
  }
  Ok(@binary.concat(parts))
}
