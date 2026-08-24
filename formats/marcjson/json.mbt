///|
fn field_object(tag : String, value : String) -> Json {
  Json::object(
    Map([("tag", Json::string(tag)), ("value", Json::string(value))]),
  )
}

///|
fn subfield_object(subfield : @record.Subfield) -> Json {
  Json::object(
    Map([
      ("code", Json::string(subfield.code.to_string())),
      ("value", Json::string(subfield.value)),
    ]),
  )
}

///|
fn field_to_json(field : @record.MarcField) -> Json {
  match field {
    @record.MarcField::ControlField(tag~, value~) => field_object(tag, value)
    @record.MarcField::DataField(tag~, indicator1~, indicator2~, subfields~) => {
      let encoded_subfields : Array[Json] = []
      for subfield in subfields {
        encoded_subfields.push(subfield_object(subfield))
      }
      Json::object(
        Map([
          ("tag", Json::string(tag)),
          (
            "indicators",
            Json::array([
              Json::string(indicator1.to_string()),
              Json::string(indicator2.to_string()),
            ]),
          ),
          ("subfields", Json::array(encoded_subfields)),
        ]),
      )
    }
  }
}

///|
/// Convert one structured MARC 21 record to the MoonMARC JSON shape.
pub fn record_to_json(record : @record.MarcRecord) -> Json {
  let fields : Array[Json] = []
  for field in record.fields() {
    fields.push(field_to_json(field))
  }
  Json::object(
    Map([
      ("leader", Json::string(record.leader().raw())),
      ("fields", Json::array(fields)),
    ]),
  )
}

///|
/// Convert multiple structured MARC records to a JSON array.
pub fn records_to_json(records : Array[@record.MarcRecord]) -> Json {
  let values : Array[Json] = []
  for record in records {
    values.push(record_to_json(record))
  }
  Json::array(values)
}

///|
/// Render one record as JSON text. The optional indent is passed to the core JSON stringifier.
pub fn record_to_json_text(
  record : @record.MarcRecord,
  indent? : Int,
) -> String {
  match indent {
    None => record_to_json(record).stringify()
    Some(width) => record_to_json(record).stringify(indent=width)
  }
}

///|
/// Render multiple records as a JSON array text.
pub fn records_to_json_text(
  records : Array[@record.MarcRecord],
  indent? : Int,
) -> String {
  match indent {
    None => records_to_json(records).stringify()
    Some(width) => records_to_json(records).stringify(indent=width)
  }
}

///|
fn expect_string(
  object : Map[String, Json],
  key : String,
) -> Result[String, JsonConversionError] {
  match object.get(key) {
    None => Err(MissingField(key))
    Some(Json::String(value)) => Ok(value)
    Some(_) => Err(WrongType(key))
  }
}

///|
fn expect_array(
  object : Map[String, Json],
  key : String,
) -> Result[Array[Json], JsonConversionError] {
  match object.get(key) {
    None => Err(MissingField(key))
    Some(Json::Array(values)) => Ok(values)
    Some(_) => Err(WrongType(key))
  }
}

///|
fn is_control_tag(tag : String) -> Bool {
  tag >= "001" && tag <= "009"
}

///|
fn valid_tag(tag : String) -> Bool {
  if tag.length() != 3 {
    return false
  }
  for character in tag {
    if character.to_int() > 0x7F {
      return false
    }
  }
  true
}

///|
fn char_from_json(
  value : Json,
  field : String,
) -> Result[Char, JsonConversionError] {
  match value {
    Json::String(text) => {
      if text.length() != 1 {
        return Err(InvalidValue(field))
      }
      let character = text.get_char(0).unwrap()
      if character.to_int() > 0x7F {
        return Err(InvalidValue(field))
      }
      Ok(character)
    }
    _ => Err(WrongType(field))
  }
}

///|
fn parse_subfield(
  value : Json,
) -> Result[@record.Subfield, JsonConversionError] {
  let object = match value {
    Json::Object(object) => object
    _ => return Err(WrongType("subfields"))
  }
  let code_text = match expect_string(object, "code") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if code_text.length() != 1 {
    return Err(InvalidValue("subfield.code"))
  }
  let code = code_text.get_char(0).unwrap()
  if code.to_int() > 0x7F {
    return Err(InvalidValue("subfield.code"))
  }
  let text = match expect_string(object, "value") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ code, value: text })
}

///|
fn parse_field(value : Json) -> Result[@record.MarcField, JsonConversionError] {
  let object = match value {
    Json::Object(object) => object
    _ => return Err(WrongType("fields"))
  }
  let tag = match expect_string(object, "tag") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if !valid_tag(tag) {
    return Err(InvalidTag(tag))
  }
  match object.get("value") {
    Some(Json::String(text)) => {
      if !is_control_tag(tag) {
        return Err(InvalidValue("value"))
      }
      Ok(@record.MarcField::ControlField(tag~, value=text))
    }
    Some(_) => Err(WrongType("value"))
    None => {
      if is_control_tag(tag) {
        return Err(InvalidValue("control field"))
      }
      let indicators = match expect_array(object, "indicators") {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if indicators.length() != 2 {
        return Err(InvalidValue("indicators"))
      }
      let indicator1 = match char_from_json(indicators[0], "indicators[0]") {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let indicator2 = match char_from_json(indicators[1], "indicators[1]") {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let subfield_values = match expect_array(object, "subfields") {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let subfields : Array[@record.Subfield] = []
      for subfield_value in subfield_values {
        subfields.push(
          match parse_subfield(subfield_value) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
        )
      }
      Ok(
        @record.MarcField::DataField(tag~, indicator1~, indicator2~, subfields~),
      )
    }
  }
}

///|
/// Convert one JSON value in the MoonMARC interchange shape to a record.
pub fn record_from_json(
  value : Json,
) -> Result[@record.MarcRecord, JsonConversionError] {
  let object = match value {
    Json::Object(object) => object
    _ => return Err(WrongType("record"))
  }
  let leader_text = match expect_string(object, "leader") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let leader = match @leader.parse(@binary.ascii(leader_text)) {
    Err(error) => return Err(InvalidLeader(error.to_string()))
    Ok(value) => value
  }
  let field_values = match expect_array(object, "fields") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let fields : Array[@record.MarcField] = []
  for field_value in field_values {
    fields.push(
      match parse_field(field_value) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    )
  }
  Ok({ leader, fields })
}

///|
/// Convert a JSON array to structured MARC 21 records.
pub fn records_from_json(
  value : Json,
) -> Result[Array[@record.MarcRecord], JsonConversionError] {
  let values = match value {
    Json::Array(values) => values
    _ => return Err(WrongType("records"))
  }
  let records : Array[@record.MarcRecord] = []
  for item in values {
    records.push(
      match record_from_json(item) {
        Err(error) => return Err(error)
        Ok(record) => record
      },
    )
  }
  Ok(records)
}

///|
/// Parse JSON text and convert it to one structured MARC 21 record.
pub fn record_from_json_text(
  text : String,
) -> Result[@record.MarcRecord, JsonConversionError] {
  let value = @json.parse(text) catch {
    error => return Err(InvalidJson(error.to_string()))
  }
  record_from_json(value)
}

///|
/// Parse JSON text containing an array of records.
pub fn records_from_json_text(
  text : String,
) -> Result[Array[@record.MarcRecord], JsonConversionError] {
  let value = @json.parse(text) catch {
    error => return Err(InvalidJson(error.to_string()))
  }
  records_from_json(value)
}
