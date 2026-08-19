///|
pub(all) suberror RecordError {
  Leader(@leader.LeaderError)
  Directory(@directory.DirectoryError)
  InvalidLength(Int, Int)
  FieldOutsideRecord(String)
  FieldTerminatorMissing(String)
  InvalidControlField(String)
  InvalidDataField(String)
  InvalidUtf8(String)
  InvalidSubfield(String)
} derive(Eq, Debug)

///|
pub impl Show for RecordError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn RecordError::to_string(self : RecordError) -> String {
  match self {
    Leader(error) => "leader: \{error}"
    Directory(error) => "directory: \{error}"
    InvalidLength(expected, actual) =>
      "record length mismatch: leader=\{expected}, actual=\{actual}"
    FieldOutsideRecord(tag) => "field \{tag} points outside the record"
    FieldTerminatorMissing(tag) => "field \{tag} is missing its terminator"
    InvalidControlField(tag) => "control field \{tag} contains subfield data"
    InvalidDataField(tag) => "data field \{tag} is too short for indicators"
    InvalidUtf8(tag) => "field \{tag} contains invalid UTF-8"
    InvalidSubfield(tag) => "data field \{tag} contains malformed subfield data"
  }
}
