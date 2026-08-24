///|
/// Errors raised while serializing a structured MARC record.
pub(all) suberror SerializeError {
  InvalidTag(String)
  InvalidIndicator(String)
  InvalidSubfieldCode(Char)
  InvalidFieldValue(String)
  ControlFieldTag(String)
  FieldTooLong(String, Int)
  DirectoryOverflow(Int)
  RecordTooLong(Int)
} derive(Eq, Debug)

///|
pub impl Show for SerializeError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn SerializeError::to_string(self : SerializeError) -> String {
  match self {
    InvalidTag(tag) => "invalid MARC tag: \{tag}"
    InvalidIndicator(tag) => "invalid indicator in field \{tag}"
    InvalidSubfieldCode(code) => "invalid subfield code: \{code}"
    InvalidFieldValue(tag) => "field \{tag} contains an ISO 2709 delimiter byte"
    ControlFieldTag(tag) => "control field uses a non-control tag: \{tag}"
    FieldTooLong(tag, length) =>
      "field \{tag} is too long for a four-digit directory length: \{length}"
    DirectoryOverflow(length) =>
      "directory offset exceeds five digits: \{length}"
    RecordTooLong(length) =>
      "record is too long for the five-digit MARC leader length: \{length}"
  }
}
