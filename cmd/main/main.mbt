///|
fn print_usage() -> Unit {
  println("MoonMARC - MARC 21 / ISO 2709 toolkit")
  println("")
  println("Usage:")
  println("  moon run cmd/main -- inspect FILE")
  println("  moon run cmd/main -- validate FILE")
  println("  moon run cmd/main -- show FILE RECORD")
  println("  moon run cmd/main -- query FILE TAG$CODE")
}

///|
fn read_input(path : String) -> Bytes? {
  Some(@fs.read_file_to_bytes(path)) catch {
    _ => None
  }
}

///|
fn print_field(field : @record.MarcField) -> Unit {
  match field {
    @record.MarcField::ControlField(tag~, value~) => println(tag + "  " + value)
    @record.MarcField::DataField(tag~, indicator1~, indicator2~, subfields~) => {
      let mut line = tag +
        "  " +
        indicator1.to_string() +
        indicator2.to_string()
      for subfield in subfields {
        line = line + " $" + subfield.code.to_string() + " " + subfield.value
      }
      println(line)
    }
  }
}

///|
fn show_record(record : @record.MarcRecord) -> Unit {
  println("Leader: " + record.leader().raw())
  for field in record.fields() {
    print_field(field)
  }
}

///|
fn print_diagnostic(diagnostic : @validation.Diagnostic) -> Unit {
  let severity = match diagnostic.severity {
    @validation.Severity::Error => "ERROR"
    @validation.Severity::Warning => "WARNING"
  }
  let mut location = " record=" + (diagnostic.record_index + 1).to_string()
  match diagnostic.tag {
    Some(tag) => location = location + " field=" + tag
    None => ()
  }
  match diagnostic.subfield {
    Some(code) => location = location + " subfield=" + code.to_string()
    None => ()
  }
  println(severity + " " + diagnostic.code + location)
  println("  " + diagnostic.message)
}

///|
fn inspect(path : String, validate_only : Bool) -> Unit {
  match read_input(path) {
    None => println("Unable to read file: " + path)
    Some(bytes) => {
      let results = @iso2709.parse_records(bytes)
      println("Records: " + results.length().to_string())
      let mut valid = 0
      for index, result in results {
        match result {
          Ok(record) if validate_only => {
            let diagnostics = @validation.validate_record(
              record,
              record_index=index,
            )
            let mut has_error = false
            for diagnostic in diagnostics {
              print_diagnostic(diagnostic)
              if diagnostic.severity == @validation.Severity::Error {
                has_error = true
              }
            }
            if !has_error {
              valid = valid + 1
            }
          }
          Ok(_) => valid = valid + 1
          Err(error) =>
            println(
              "ERROR record=" +
              (index + 1).to_string() +
              "\n  " +
              error.to_string(),
            )
        }
      }
      if validate_only {
        println("Valid: " + valid.to_string())
        println("Errors: " + (results.length() - valid).to_string())
      }
    }
  }
}

///|
fn show(path : String, index : Int) -> Unit {
  match read_input(path) {
    None => println("Unable to read file: " + path)
    Some(bytes) => {
      let results = @iso2709.parse_records(bytes)
      if index < 1 || index > results.length() {
        println("Record index out of range: " + index.to_string())
      } else {
        match results[index - 1] {
          Err(error) => println("ERROR: " + error.to_string())
          Ok(record) => show_record(record)
        }
      }
    }
  }
}

///|
fn query(path : String, expression : String) -> Unit {
  let compiled = match @query.parse(expression) {
    Err(error) => {
      println("Invalid query: " + error.to_string())
      return
    }
    Ok(value) => value
  }
  match read_input(path) {
    None => println("Unable to read file: " + path)
    Some(bytes) => {
      let results = @iso2709.parse_records(bytes)
      for result in results {
        match result {
          Err(error) => println("ERROR: " + error.to_string())
          Ok(record) =>
            for value in compiled.evaluate(record) {
              println(value)
            }
        }
      }
    }
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }
  let command = args[1]
  match command {
    "inspect" if args.length() >= 3 => inspect(args[2], false)
    "validate" if args.length() >= 3 => inspect(args[2], true)
    "show" if args.length() >= 4 =>
      show(args[2], @string.parse_int(args[3])) catch {
        _ => println("Record index must be an integer: " + args[3])
      }
    "query" if args.length() >= 4 => query(args[2], args[3])
    _ => print_usage()
  }
}
