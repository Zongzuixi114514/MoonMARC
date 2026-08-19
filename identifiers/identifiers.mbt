///|
fn compact_identifier(value : String) -> Array[Char] {
  let chars : Array[Char] = []
  for char in value {
    if char != '-' && char != ' ' {
      chars.push(char)
    }
  }
  chars
}

///|
fn decimal_digit(char : Char) -> Int? {
  let value = char.to_int()
  if value >= 48 && value <= 57 {
    Some(value - 48)
  } else {
    None
  }
}

///|
/// Validate an ISBN-10, accepting spaces and hyphens as separators.
pub fn is_valid_isbn10(value : String) -> Bool {
  let chars = compact_identifier(value)
  if chars.length() != 10 {
    return false
  }
  let mut sum = 0
  let mut index = 0
  while index < 10 {
    let digit = if index == 9 && (chars[index] == 'X' || chars[index] == 'x') {
      10
    } else {
      match decimal_digit(chars[index]) {
        None => return false
        Some(value) => value
      }
    }
    sum = sum + digit * (10 - index)
    index = index + 1
  }
  sum % 11 == 0
}

///|
/// Validate an ISBN-13, accepting spaces and hyphens as separators.
pub fn is_valid_isbn13(value : String) -> Bool {
  let chars = compact_identifier(value)
  if chars.length() != 13 {
    return false
  }
  let mut sum = 0
  let mut index = 0
  while index < 13 {
    let digit = match decimal_digit(chars[index]) {
      None => return false
      Some(value) => value
    }
    let weight = if index % 2 == 0 { 1 } else { 3 }
    sum = sum + digit * weight
    index = index + 1
  }
  sum % 10 == 0
}

///|
/// Validate either an ISBN-10 or ISBN-13.
pub fn is_valid_isbn(value : String) -> Bool {
  let length = compact_identifier(value).length()
  if length == 10 {
    is_valid_isbn10(value)
  } else if length == 13 {
    is_valid_isbn13(value)
  } else {
    false
  }
}

///|
/// Validate an ISSN, accepting spaces and hyphens as separators.
pub fn is_valid_issn(value : String) -> Bool {
  let chars = compact_identifier(value)
  if chars.length() != 8 {
    return false
  }
  let mut sum = 0
  let mut index = 0
  while index < 8 {
    let digit = if index == 7 && (chars[index] == 'X' || chars[index] == 'x') {
      10
    } else {
      match decimal_digit(chars[index]) {
        None => return false
        Some(value) => value
      }
    }
    sum = sum + digit * (8 - index)
    index = index + 1
  }
  sum % 11 == 0
}
