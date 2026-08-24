///|
/// Errors raised when converting between MARC records and the JSON interchange shape.
pub(all) suberror JsonConversionError {
  InvalidJson(String)
  MissingField(String)
  WrongType(String)
  InvalidValue(String)
  InvalidLeader(String)
  InvalidTag(String)
} derive(Eq, Debug)

///|
pub impl Show for JsonConversionError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn JsonConversionError::to_string(self : JsonConversionError) -> String {
  match self {
    InvalidJson(message) => "invalid JSON: \{message}"
    MissingField(field) => "missing JSON field: \{field}"
    WrongType(field) => "wrong JSON type for field: \{field}"
    InvalidValue(field) => "invalid JSON value for field: \{field}"
    InvalidLeader(message) => "invalid MARC leader: \{message}"
    InvalidTag(tag) => "invalid MARC tag: \{tag}"
  }
}
