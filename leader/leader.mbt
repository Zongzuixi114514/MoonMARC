///|
/// The fixed 24-byte MARC 21 record leader.
pub struct Leader {
  raw : String
} derive(Eq, Debug)

///|
pub(all) suberror LeaderError {
  InvalidLength(Int)
  NonAscii(Int)
  InvalidEntryMap(String)
  InvalidRecordLength(String)
  InvalidBaseAddress(String)
} derive(Eq, Debug)

///|
pub impl Show for LeaderError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn LeaderError::to_string(self : LeaderError) -> String {
  match self {
    InvalidLength(length) => "MARC leader must contain 24 bytes, got \{length}"
    NonAscii(offset) =>
      "MARC leader contains a non-ASCII byte at offset \{offset}"
    InvalidEntryMap(value) => "invalid MARC leader entry map: \{value}"
    InvalidRecordLength(value) => "invalid leader record length: \{value}"
    InvalidBaseAddress(value) => "invalid leader base address: \{value}"
  }
}

///|
pub fn parse(raw : Bytes) -> Result[Leader, LeaderError] {
  if raw.length() != 24 {
    return Err(InvalidLength(raw.length()))
  }
  let chars : Array[Char] = []
  let mut index = 0
  while index < 24 {
    let value = raw[index].to_int()
    if value > 0x7F {
      return Err(NonAscii(index))
    }
    chars.push(value.unsafe_to_char())
    index = index + 1
  }
  Ok({ raw: String::from_array(chars) })
}

///|
fn field(raw : String, start : Int, end : Int) -> String {
  raw.unsafe_substring(start~, end~)
}

///|
fn decimal(raw : String, start : Int, end : Int) -> Int? {
  let mut result = 0
  let mut index = start
  while index < end {
    let value = raw[index].to_int()
    if value < 48 || value > 57 {
      return None
    }
    result = result * 10 + value - 48
    index = index + 1
  }
  Some(result)
}

///|
pub fn Leader::raw(self : Leader) -> String {
  self.raw
}

///|
pub fn Leader::record_length(self : Leader) -> Result[Int, LeaderError] {
  match decimal(self.raw, 0, 5) {
    Some(value) => Ok(value)
    None => Err(InvalidRecordLength(field(self.raw, 0, 5)))
  }
}

///|
pub fn Leader::status(self : Leader) -> Char {
  self.raw.get_char(5).unwrap()
}

///|
pub fn Leader::record_type(self : Leader) -> Char {
  self.raw.get_char(6).unwrap()
}

///|
pub fn Leader::bibliographic_level(self : Leader) -> Char {
  self.raw.get_char(7).unwrap()
}

///|
pub fn Leader::type_of_control(self : Leader) -> Char {
  self.raw.get_char(8).unwrap()
}

///|
pub fn Leader::character_coding_scheme(self : Leader) -> Char {
  self.raw.get_char(9).unwrap()
}

///|
pub fn Leader::indicator_count(self : Leader) -> Result[Int, LeaderError] {
  match decimal(self.raw, 10, 11) {
    Some(value) => Ok(value)
    None => Err(InvalidEntryMap(field(self.raw, 10, 11)))
  }
}

///|
pub fn Leader::subfield_code_length(self : Leader) -> Result[Int, LeaderError] {
  match decimal(self.raw, 11, 12) {
    Some(value) => Ok(value)
    None => Err(InvalidEntryMap(field(self.raw, 11, 12)))
  }
}

///|
pub fn Leader::base_address(self : Leader) -> Result[Int, LeaderError] {
  match decimal(self.raw, 12, 17) {
    Some(value) => Ok(value)
    None => Err(InvalidBaseAddress(field(self.raw, 12, 17)))
  }
}

///|
pub fn Leader::encoding_level(self : Leader) -> Char {
  self.raw.get_char(17).unwrap()
}

///|
pub fn Leader::cataloging_form(self : Leader) -> Char {
  self.raw.get_char(18).unwrap()
}

///|
pub fn Leader::multipart_level(self : Leader) -> Char {
  self.raw.get_char(19).unwrap()
}

///|
pub fn Leader::entry_map(self : Leader) -> Result[(Int, Int, Int), LeaderError] {
  let length_of_length = match decimal(self.raw, 20, 21) {
    Some(value) => value
    None => return Err(InvalidEntryMap(field(self.raw, 20, 21)))
  }
  let length_of_start = match decimal(self.raw, 21, 22) {
    Some(value) => value
    None => return Err(InvalidEntryMap(field(self.raw, 21, 22)))
  }
  let length_of_implementation = match decimal(self.raw, 22, 23) {
    Some(value) => value
    None => return Err(InvalidEntryMap(field(self.raw, 22, 23)))
  }
  if self.raw.get_char(23).unwrap() != '0' {
    return Err(InvalidEntryMap(field(self.raw, 20, 24)))
  }
  Ok((length_of_length, length_of_start, length_of_implementation))
}
