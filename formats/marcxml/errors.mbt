///|
/// Errors raised while reading or writing the supported MARCXML subset.
pub(all) suberror MarcXmlError {
  InvalidDocument(String)
  MissingElement(String)
  InvalidAttribute(String)
  InvalidLeader(String)
  InvalidTag(String)
  InvalidSubfield(String)
} derive(Eq, Debug)

///|
pub impl Show for MarcXmlError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn MarcXmlError::to_string(self : MarcXmlError) -> String {
  match self {
    InvalidDocument(message) => "invalid MARCXML document: \{message}"
    MissingElement(name) => "missing MARCXML element: \{name}"
    InvalidAttribute(name) => "invalid MARCXML attribute: \{name}"
    InvalidLeader(message) => "invalid MARC leader: \{message}"
    InvalidTag(tag) => "invalid MARC tag: \{tag}"
    InvalidSubfield(message) => "invalid MARC subfield: \{message}"
  }
}
