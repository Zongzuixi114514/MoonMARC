///|
/// Failures produced by bounded byte reads and text decoding.
pub(all) suberror ReadError {
  InvalidRange(Int, Int)
  Truncated(Int, Int, Int)
  InvalidAscii(Int, Int)
  InvalidDecimal(Int, Int)
  InvalidUtf8(Int, Int)
} derive(Eq, Debug)

///|
impl Show for ReadError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn ReadError::to_string(self : ReadError) -> String {
  match self {
    InvalidRange(start, end) => "invalid byte range [\{start}, \{end})"
    Truncated(offset, need, available) =>
      "truncated input at byte \{offset}: need \{need} bytes, have \{available}"
    InvalidAscii(offset, value) =>
      "non-ASCII byte 0x\{value.to_byte().to_hex()} at byte \{offset}"
    InvalidDecimal(offset, value) =>
      "expected decimal digit at byte \{offset}, got 0x\{value.to_byte().to_hex()}"
    InvalidUtf8(offset, length) =>
      "invalid UTF-8 in byte range [\{offset}, \{offset + length})"
  }
}

///|
/// A cursor that never reads outside the configured byte range.
pub struct Reader {
  data : Bytes
  start : Int
  limit : Int
  mut position : Int
}

///|
pub fn Reader::new(
  data : Bytes,
  start? : Int = 0,
  limit? : Int = data.length(),
) -> Result[Reader, ReadError] {
  if start < 0 || limit < start || limit > data.length() {
    Err(InvalidRange(start, limit))
  } else {
    Ok({ data, start, limit, position: start })
  }
}

///|
pub fn Reader::position(self : Reader) -> Int {
  self.position
}

///|
pub fn Reader::remaining(self : Reader) -> Int {
  self.limit - self.position
}

///|
pub fn Reader::seek(self : Reader, position : Int) -> Result[Unit, ReadError] {
  if position < self.start || position > self.limit {
    Err(InvalidRange(position, self.limit))
  } else {
    self.position = position
    Ok(())
  }
}

///|
pub fn Reader::read_byte(self : Reader) -> Result[Byte, ReadError] {
  if self.remaining() < 1 {
    Err(Truncated(self.position, 1, self.remaining()))
  } else {
    let value = self.data[self.position]
    self.position = self.position + 1
    Ok(value)
  }
}

///|
pub fn Reader::read_bytes(
  self : Reader,
  length : Int,
) -> Result[Bytes, ReadError] {
  if length < 0 {
    return Err(InvalidRange(self.position, self.position + length))
  }
  if self.remaining() < length {
    return Err(Truncated(self.position, length, self.remaining()))
  }
  let start = self.position
  self.position = self.position + length
  Ok(slice(self.data, start, start + length))
}

///|
pub fn Reader::read_ascii(
  self : Reader,
  length : Int,
) -> Result[String, ReadError] {
  let start = self.position
  let bytes = match self.read_bytes(length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let chars : Array[Char] = []
  let mut index = 0
  while index < bytes.length() {
    let value = bytes[index].to_int()
    if value > 0x7F {
      return Err(InvalidAscii(start + index, value))
    }
    chars.push(value.unsafe_to_char())
    index = index + 1
  }
  Ok(String::from_array(chars))
}

///|
pub fn Reader::read_decimal(
  self : Reader,
  length : Int,
) -> Result[Int, ReadError] {
  let start = self.position
  let bytes = match self.read_bytes(length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut result = 0
  let mut index = 0
  while index < bytes.length() {
    let value = bytes[index].to_int()
    if value < 48 || value > 57 {
      return Err(InvalidDecimal(start + index, value))
    }
    result = result * 10 + value - 48
    index = index + 1
  }
  Ok(result)
}

///|
pub fn decode_utf8(
  data : Bytes,
  offset? : Int = 0,
  length? : Int = data.length() - offset,
) -> Result[String, ReadError] {
  if offset < 0 || length < 0 || offset + length > data.length() {
    return Err(InvalidRange(offset, offset + length))
  }
  let piece = slice(data, offset, offset + length)
  Ok(@utf8.decode(piece[:])) catch {
    _ => Err(InvalidUtf8(offset, length))
  }
}
