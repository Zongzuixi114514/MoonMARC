///|
/// One ISO 2709 directory entry.
pub(all) struct DirectoryEntry {
  tag : String
  length : Int
  start : Int
} derive(Eq, Debug)

///|
pub(all) suberror DirectoryError {
  Truncated(Int)
  InvalidDirectoryLength(Int)
  InvalidEntry(String)
  InvalidTag(String)
  InvalidFieldLength(String)
  InvalidFieldStart(String)
  MissingTerminator
} derive(Eq, Debug)

///|
pub impl Show for DirectoryError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn DirectoryError::to_string(self : DirectoryError) -> String {
  match self {
    Truncated(need) => "truncated directory: need \{need} more bytes"
    InvalidDirectoryLength(length) =>
      "directory length is not divisible by entry width: \{length}"
    InvalidEntry(value) => "invalid directory entry: \{value}"
    InvalidTag(value) => "invalid directory tag: \{value}"
    InvalidFieldLength(value) => "invalid directory field length: \{value}"
    InvalidFieldStart(value) => "invalid directory field start: \{value}"
    MissingTerminator => "directory is missing the field terminator"
  }
}

///|
fn digits(value : String) -> Int? {
  let mut result = 0
  if value.is_empty() {
    return None
  }
  for char in value {
    let digit = char.to_int()
    if digit < 48 || digit > 57 {
      return None
    }
    result = result * 10 + digit - 48
  }
  Some(result)
}

///|
fn ascii_field(raw : Bytes, offset : Int, length : Int) -> String? {
  let chars : Array[Char] = []
  let mut index = 0
  while index < length {
    let value = raw[offset + index].to_int()
    if value > 0x7F {
      return None
    }
    chars.push(value.unsafe_to_char())
    index = index + 1
  }
  Some(String::from_array(chars))
}

///|
/// Parse the directory occupying bytes 24 through `leader.base_address() - 1`.
pub fn parse(
  raw : Bytes,
  leader : @leader.Leader,
) -> Result[Array[DirectoryEntry], DirectoryError] {
  let base_address = match leader.base_address() {
    Err(_) => return Err(InvalidEntry("invalid leader base address"))
    Ok(value) => value
  }
  let map = match leader.entry_map() {
    Err(_) => return Err(InvalidEntry("invalid leader entry map"))
    Ok(value) => value
  }
  let tag_width = 3
  let length_width = map.0
  let start_width = map.1 + map.2
  let entry_width = tag_width + length_width + start_width
  if entry_width <= 0 || base_address < 25 || base_address > raw.length() {
    return Err(InvalidDirectoryLength(base_address))
  }
  let directory_bytes = base_address - 24 - 1
  if directory_bytes < 0 || directory_bytes % entry_width != 0 {
    return Err(InvalidDirectoryLength(directory_bytes))
  }
  if raw[base_address - 1].to_int() != 0x1E {
    return Err(MissingTerminator)
  }
  let entries : Array[DirectoryEntry] = []
  let mut offset = 24
  while offset < base_address - 1 {
    let tag = match ascii_field(raw, offset, tag_width) {
      None => return Err(InvalidTag("non-ASCII tag"))
      Some(value) => value
    }
    let length_text = match ascii_field(raw, offset + tag_width, length_width) {
      None => return Err(InvalidFieldLength("non-ASCII length"))
      Some(value) => value
    }
    let start_text = match
      ascii_field(raw, offset + tag_width + length_width, start_width) {
      None => return Err(InvalidFieldStart("non-ASCII start"))
      Some(value) => value
    }
    let length = match digits(length_text) {
      None => return Err(InvalidFieldLength(length_text))
      Some(value) => value
    }
    let start = match digits(start_text) {
      None => return Err(InvalidFieldStart(start_text))
      Some(value) => value
    }
    if tag.length() != 3 {
      return Err(InvalidTag(tag))
    }
    entries.push({ tag, length, start })
    offset = offset + entry_width
  }
  Ok(entries)
}
