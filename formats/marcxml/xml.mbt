///|
const MARCXML_NAMESPACE : String = "http://www.loc.gov/MARC21/slim"

///|
fn xml_escape(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&apos;")
}

///|
fn xml_unescape(value : String) -> String {
  value
  .replace_all(old="&lt;", new="<")
  .replace_all(old="&gt;", new=">")
  .replace_all(old="&quot;", new="\"")
  .replace_all(old="&apos;", new="'")
  .replace_all(old="&amp;", new="&")
}

///|
fn substring(text : String, start : Int, end : Int) -> String {
  text.unsafe_substring(start~, end~)
}

///|
fn find_from(text : String, needle : String, start : Int) -> Int? {
  if start >= text.length() {
    return None
  }
  match substring(text, start, text.length()).find(needle) {
    None => None
    Some(offset) => Some(start + offset)
  }
}

///|
fn element_bounds(
  text : String,
  name : String,
  start : Int,
) -> Result[(Int, Int, Int), MarcXmlError] {
  let open = "<" + name
  let open_start = match find_from(text, open, start) {
    None => return Err(MissingElement(name))
    Some(value) => value
  }
  let open_end = match find_from(text, ">", open_start) {
    None => return Err(InvalidDocument("unterminated opening element"))
    Some(value) => value
  }
  let close_marker = "</" + name + ">"
  let close_start = match find_from(text, close_marker, open_end + 1) {
    None => return Err(InvalidDocument("missing closing element " + name))
    Some(value) => value
  }
  Ok((open_start, open_end, close_start))
}

///|
fn element_text(
  text : String,
  name : String,
  start : Int,
) -> Result[(String, Int), MarcXmlError] {
  let (_, open_end, close_start) = match element_bounds(text, name, start) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let close_end = close_start + name.length() + 3
  Ok((xml_unescape(substring(text, open_end + 1, close_start)), close_end))
}

///|
fn attribute(
  text : String,
  name : String,
  start : Int,
  end : Int,
) -> Result[String, MarcXmlError] {
  let marker = name + "=\""
  let position = match find_from(substring(text, 0, end), marker, start) {
    None => return Err(InvalidAttribute(name))
    Some(value) => value + marker.length()
  }
  let quote = match find_from(text, "\"", position) {
    None => return Err(InvalidDocument("unterminated attribute " + name))
    Some(value) => value
  }
  if quote > end {
    return Err(InvalidAttribute(name))
  }
  Ok(xml_unescape(substring(text, position, quote)))
}

///|
fn valid_tag(tag : String) -> Bool {
  if tag.length() != 3 {
    return false
  }
  for char in tag {
    if char.to_int() > 0x7F {
      return false
    }
  }
  true
}

///|
fn field_to_xml(field : @record.MarcField) -> String {
  match field {
    @record.MarcField::ControlField(tag~, value~) =>
      "  <controlfield tag=\"" +
      tag +
      "\">" +
      xml_escape(value) +
      "</controlfield>\n"
    @record.MarcField::DataField(tag~, indicator1~, indicator2~, subfields~) => {
      let mut result = "  <datafield tag=\"" +
        tag +
        "\" ind1=\"" +
        xml_escape(indicator1.to_string()) +
        "\" ind2=\"" +
        xml_escape(indicator2.to_string()) +
        "\">\n"
      for subfield in subfields {
        result = result +
          "    <subfield code=\"" +
          xml_escape(subfield.code.to_string()) +
          "\">" +
          xml_escape(subfield.value) +
          "</subfield>\n"
      }
      result + "  </datafield>\n"
    }
  }
}

///|
/// Convert one structured MARC 21 record to MARCXML.
pub fn record_to_xml(record : @record.MarcRecord) -> String {
  let mut result = "<record xmlns=\"" + MARCXML_NAMESPACE + "\">\n"
  result = result +
    "  <leader>" +
    xml_escape(record.leader().raw()) +
    "</leader>\n"
  for field in record.fields() {
    result = result + field_to_xml(field)
  }
  result + "</record>"
}

///|
/// Convert multiple records to a MARCXML collection.
pub fn records_to_xml(records : Array[@record.MarcRecord]) -> String {
  let mut result = "<collection xmlns=\"" + MARCXML_NAMESPACE + "\">\n"
  for record in records {
    result = result + record_to_xml(record) + "\n"
  }
  result + "</collection>"
}

///|
fn parse_subfields(
  text : String,
  start : Int,
  end : Int,
) -> Result[Array[@record.Subfield], MarcXmlError] {
  let subfields : Array[@record.Subfield] = []
  let mut cursor = start
  while cursor < end {
    let position = match find_from(text, "<subfield", cursor) {
      None => break
      Some(value) => value
    }
    if position >= end {
      break
    }
    let opening_end = match find_from(text, ">", position) {
      None => return Err(InvalidDocument("unterminated subfield"))
      Some(value) => value
    }
    let close = match find_from(text, "</subfield>", opening_end + 1) {
      None => return Err(InvalidDocument("missing subfield closing tag"))
      Some(value) => value
    }
    let code = match attribute(text, "code", position, opening_end) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if code.length() != 1 {
      return Err(InvalidSubfield("code must contain one character"))
    }
    let code = code.get_char(0).unwrap()
    let value = xml_unescape(substring(text, opening_end + 1, close))
    subfields.push({ code, value })
    cursor = close + 11
  }
  Ok(subfields)
}

///|
fn parse_record_fragment(
  text : String,
) -> Result[@record.MarcRecord, MarcXmlError] {
  let (record_start, record_open_end, record_close_start) = match
    element_bounds(text, "record", 0) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let body_start = record_open_end + 1
  let leader_text = match element_text(text, "leader", body_start) {
    Err(error) => return Err(error)
    Ok(value) => value.0
  }
  let leader = match @leader.parse(@binary.ascii(leader_text)) {
    Err(error) => return Err(InvalidLeader(error.to_string()))
    Ok(value) => value
  }
  let fields : Array[@record.MarcField] = []
  let mut cursor = body_start
  while cursor < record_close_start {
    let control_position = find_from(text, "<controlfield", cursor)
    let data_position = find_from(text, "<datafield", cursor)
    let position = match (control_position, data_position) {
      (None, None) => break
      (Some(value), None) => value
      (None, Some(value)) => value
      (Some(left), Some(right)) => if left < right { left } else { right }
    }
    if position >= record_close_start {
      break
    }
    let is_control = match text.get_char(position + 1) {
      Some('c') => true
      _ => false
    }
    if is_control {
      let (open_start, open_end, close_start) = match
        element_bounds(text, "controlfield", position) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let tag = match attribute(text, "tag", open_start, open_end) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if !valid_tag(tag) || tag > "009" {
        return Err(InvalidTag(tag))
      }
      let value = xml_unescape(substring(text, open_end + 1, close_start))
      fields.push(@record.MarcField::ControlField(tag~, value~))
      cursor = close_start + 14
    } else {
      let (open_start, open_end, close_start) = match
        element_bounds(text, "datafield", position) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let tag = match attribute(text, "tag", open_start, open_end) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if !valid_tag(tag) || tag <= "009" {
        return Err(InvalidTag(tag))
      }
      let indicator1 = match attribute(text, "ind1", open_start, open_end) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let indicator2 = match attribute(text, "ind2", open_start, open_end) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if indicator1.length() != 1 || indicator2.length() != 1 {
        return Err(InvalidAttribute("indicators"))
      }
      let subfields = match parse_subfields(text, open_end + 1, close_start) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      fields.push(
        @record.MarcField::DataField(
          tag~,
          indicator1=indicator1.get_char(0).unwrap(),
          indicator2=indicator2.get_char(0).unwrap(),
          subfields~,
        ),
      )
      cursor = close_start + 12
    }
  }
  let _ = record_start
  Ok({ leader, fields })
}

///|
/// Convert one MARCXML record to a structured MARC 21 record.
pub fn record_from_xml(
  text : String,
) -> Result[@record.MarcRecord, MarcXmlError] {
  parse_record_fragment(text)
}

///|
/// Convert a MARCXML record or collection to structured records.
pub fn records_from_xml(
  text : String,
) -> Result[Array[@record.MarcRecord], MarcXmlError] {
  let records : Array[@record.MarcRecord] = []
  let mut cursor = 0
  while cursor < text.length() {
    let position = match find_from(text, "<record", cursor) {
      None => break
      Some(value) => value
    }
    let close = match find_from(text, "</record>", position) {
      None => return Err(InvalidDocument("missing record closing tag"))
      Some(value) => value + 9
    }
    let fragment = substring(text, position, close)
    records.push(
      match parse_record_fragment(fragment) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    )
    cursor = close
  }
  if records.is_empty() {
    return Err(MissingElement("record"))
  }
  Ok(records)
}
