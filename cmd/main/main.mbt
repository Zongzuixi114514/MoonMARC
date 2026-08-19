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
fn inspect(path : String, validate_only : Bool) -> Unit {
  match read_input(path) {
    None => println("Unable to read file: " + path)
    Some(bytes) => {
      let results = @iso2709.parse_records(bytes)
      println("Records: " + results.length().to_string())
      let mut valid = 0
      for result in results {
        match result {
          Ok(_) => valid = valid + 1
          Err(error) if validate_only => println("ERROR: " + error.to_string())
          Err(error) => println("ERROR: " + error.to_string())
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
  let separator = match expression.find("$") {
    None => -1
    Some(value) => value
  }
  if separator < 0 || separator + 1 >= expression.length() {
    println("Query must look like TAG$CODE, for example 245$a")
    return
  }
  let tag = expression[:separator].to_owned()
  let code = expression.get_char(separator + 1).unwrap()
  match read_input(path) {
    None => println("Unable to read file: " + path)
    Some(bytes) => {
      let results = @iso2709.parse_records(bytes)
      for result in results {
        match result {
          Err(error) => println("ERROR: " + error.to_string())
          Ok(record) =>
            match record.first_subfield(tag, code) {
              None => ()
              Some(value) => println(value)
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
