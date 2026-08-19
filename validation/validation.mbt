///|
pub(all) enum Severity {
  Error
  Warning
} derive(Eq, Debug)

///|
/// A semantic MARC 21 validation finding.
pub(all) struct Diagnostic {
  severity : Severity
  code : String
  message : String
  record_index : Int
  tag : String?
  subfield : Char?
} derive(Eq, Debug)

///|
fn diagnostic(
  severity : Severity,
  code : String,
  message : String,
  record_index : Int,
  tag? : String,
  subfield? : Char,
) -> Diagnostic {
  { severity, code, message, record_index, tag, subfield }
}

///|
fn identifier_token(value : String) -> String {
  let chars : Array[Char] = []
  for char in value {
    if char == ' ' || char == '(' {
      break
    }
    chars.push(char)
  }
  String::from_array(chars)
}

///|
fn valid_indicator(value : Char) -> Bool {
  value == ' ' || (value >= '0' && value <= '9')
}

///|
/// Validate common MARC 21 bibliographic rules for one parsed record.
pub fn validate_record(
  record : @record.MarcRecord,
  record_index? : Int = 0,
) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  let titles = record.fields_by_tag("245")
  if titles.is_empty() {
    diagnostics.push(
      diagnostic(
        Error,
        "BIB245",
        "Record does not contain a 245 title field.",
        record_index,
        tag="245",
      ),
    )
  } else {
    for field in titles {
      match field {
        @record.MarcField::DataField(indicator1~, indicator2~, subfields~, ..) => {
          if !valid_indicator(indicator1) || !valid_indicator(indicator2) {
            diagnostics.push(
              diagnostic(
                Error,
                "BIB245_IND",
                "Title field contains an invalid indicator.",
                record_index,
                tag="245",
              ),
            )
          }
          let mut has_title = false
          for subfield in subfields {
            if subfield.code == 'a' && !subfield.value.trim().is_empty() {
              has_title = true
            }
          }
          if !has_title {
            diagnostics.push(
              diagnostic(
                Warning,
                "BIB245_A",
                "Title field does not contain a non-empty subfield $a.",
                record_index,
                tag="245",
                subfield='a',
              ),
            )
          }
        }
        _ =>
          diagnostics.push(
            diagnostic(
              Error,
              "BIB245_TYPE",
              "Title tag 245 must be encoded as a data field.",
              record_index,
              tag="245",
            ),
          )
      }
    }
  }
  for value in record.subfields("020", 'a') {
    if !@identifiers.is_valid_isbn(identifier_token(value)) {
      diagnostics.push(
        diagnostic(
          Warning,
          "ISBN001",
          "Invalid ISBN check digit or syntax: " + value,
          record_index,
          tag="020",
          subfield='a',
        ),
      )
    }
  }
  for value in record.subfields("022", 'a') {
    if !@identifiers.is_valid_issn(identifier_token(value)) {
      diagnostics.push(
        diagnostic(
          Warning,
          "ISSN001",
          "Invalid ISSN check digit or syntax: " + value,
          record_index,
          tag="022",
          subfield='a',
        ),
      )
    }
  }
  diagnostics
}

///|
/// Report duplicate 001 control numbers across a parsed dataset.
pub fn validate_unique_control_numbers(
  records : Array[@record.MarcRecord],
) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  let seen : Map[String, Int] = Map([])
  for index, record in records {
    match record.control_number() {
      None => ()
      Some(value) =>
        match seen.get(value) {
          None => seen[value] = index
          Some(first_index) =>
            diagnostics.push(
              diagnostic(
                Error,
                "BIB001_DUP",
                "Control number duplicates record " +
                (first_index + 1).to_string() +
                ".",
                index,
                tag="001",
              ),
            )
        }
    }
  }
  diagnostics
}
