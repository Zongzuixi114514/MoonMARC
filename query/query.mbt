///|
/// A compiled MARC subfield query such as `245$a`.
pub(all) struct Query {
  tag : String
  code : Char
} derive(Eq, Debug)

///|
pub(all) suberror QueryError {
  InvalidLength(Int)
  InvalidTag(String)
  MissingSeparator
  InvalidCode(Char)
} derive(Eq, Debug)

///|
pub impl Show for QueryError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn QueryError::to_string(self : QueryError) -> String {
  match self {
    InvalidLength(length) =>
      "query must contain exactly five ASCII characters, got \{length}"
    InvalidTag(tag) => "query contains an invalid MARC tag: \{tag}"
    MissingSeparator => "query must use '$' between tag and subfield code"
    InvalidCode(code) => "query contains an invalid subfield code: \{code}"
  }
}

///|
fn is_ascii_alphanumeric(char : Char) -> Bool {
  let value = char.to_int()
  (value >= 48 && value <= 57) ||
  (value >= 65 && value <= 90) ||
  (value >= 97 && value <= 122)
}

///|
/// Parse a MARC query expression such as `245$a`.
pub fn parse(expression : String) -> Result[Query, QueryError] {
  if expression.length() != 5 {
    return Err(InvalidLength(expression.length()))
  }
  if expression[3] != '$' {
    return Err(MissingSeparator)
  }
  let tag = expression[:3].to_owned()
  for char in tag {
    if !is_ascii_alphanumeric(char) {
      return Err(InvalidTag(tag))
    }
  }
  let code = expression.get_char(4).unwrap()
  if !is_ascii_alphanumeric(code) {
    return Err(InvalidCode(code))
  }
  Ok({ tag, code })
}

///|
/// Evaluate a compiled query against one MARC record.
pub fn Query::evaluate(
  self : Query,
  record : @record.MarcRecord,
) -> Array[String] {
  record.subfields(self.tag, self.code)
}

///|
/// Parse and evaluate one query expression.
pub fn select(
  record : @record.MarcRecord,
  expression : String,
) -> Result[Array[String], QueryError] {
  match parse(expression) {
    Err(error) => Err(error)
    Ok(query) => Ok(query.evaluate(record))
  }
}
