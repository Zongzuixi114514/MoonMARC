///| Builders for small byte sequences used by the parser and tests.
pub fn concat(parts : Array[Bytes]) -> Bytes {
  let mut total = 0
  for part in parts {
    total = total + part.length()
  }
  let data : FixedArray[Byte] = FixedArray::make(total, 0)
  let mut offset = 0
  for part in parts {
    let mut index = 0
    while index < part.length() {
      data[offset + index] = part[index]
      index = index + 1
    }
    offset = offset + part.length()
  }
  Bytes::from_array(data)
}

///|
/// Copy bytes in the half-open range `[start, end)`.
pub fn slice(raw : Bytes, start : Int, end : Int) -> Bytes {
  let length = end - start
  let data : FixedArray[Byte] = FixedArray::make(length, 0)
  let mut index = 0
  while index < length {
    data[index] = raw[start + index]
    index = index + 1
  }
  Bytes::from_array(data)
}

///|
pub fn ascii(value : String) -> Bytes {
  let data : FixedArray[Byte] = FixedArray::make(value.length(), 0)
  let mut index = 0
  while index < value.length() {
    data[index] = value[index].to_int().to_byte()
    index = index + 1
  }
  Bytes::from_array(data)
}
