///|
fn print_usage() -> Unit {
  println("MoonMARC - MARC 21 / ISO 2709 toolkit")
  println("")
  println("Usage:")
  println("  moon run cmd/main -- inspect FILE")
  println("  moon run cmd/main -- validate FILE")
  println("  moon run cmd/main -- show FILE [RECORD|--record RECORD]")
  println("  moon run cmd/main -- query FILE TAG$CODE")
  println(
    "  moon run cmd/main -- convert FILE --format json [--pretty|--indent N] [--output FILE]",
  )
  println("  moon run cmd/main -- convert FILE --format marcxml --output FILE")
  println("  moon run cmd/main -- convert FILE --format mrc --output FILE")
  println("  moon run cmd/main -- privacy FILE")
  println(
    "  moon run cmd/main -- redact FILE --drop-9xx --mask-email --output FILE",
  )
  println("  moon run cmd/main -- stats FILE")
}

///|
fn read_input(path : String) -> Bytes? {
  Some(@fs.read_file_to_bytes(path)) catch {
    _ => None
  }
}

///|
fn read_text(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => None
  }
}

///|

///|
fn write_text(path : String, text : String) -> Bool {
  let _ = @fs.write_string_to_file(path, text) catch { _ => return false }
  true
}

///|
fn write_bytes(path : String, bytes : Bytes) -> Bool {
  let _ = @fs.write_bytes_to_file(path, bytes) catch { _ => return false }
  true
}

///|
fn option_value(args : Array[String], name : String) -> String? {
  let mut index = 3
  while index + 1 < args.length() {
    if args[index] == name {
      return Some(args[index + 1])
    }
    index = index + 1
  }
  None
}

///|
fn has_flag(args : Array[String], name : String) -> Bool {
  let mut index = 3
  while index < args.length() {
    if args[index] == name {
      return true
    }
    index = index + 1
  }
  false
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
fn convert_mrc_to_json(path : String, output : String?, indent : Int?) -> Unit {
  let bytes = match read_input(path) {
    None => {
      println("Unable to read file: " + path)
      return
    }
    Some(value) => value
  }
  let parsed = @iso2709.parse_records(bytes)
  let records : Array[@record.MarcRecord] = []
  for index, result in parsed {
    match result {
      Err(error) => {
        println(
          "ERROR record=" + (index + 1).to_string() + "\n  " + error.to_string(),
        )
        return
      }
      Ok(record) => records.push(record)
    }
  }
  let text = match records.length() {
    1 =>
      match indent {
        None => @marcjson.record_to_json_text(records[0])
        Some(width) => @marcjson.record_to_json_text(records[0], indent=width)
      }
    _ =>
      match indent {
        None => @marcjson.records_to_json_text(records)
        Some(width) => @marcjson.records_to_json_text(records, indent=width)
      }
  }
  match output {
    None => println(text)
    Some(path) =>
      if write_text(path, text + "\n") {
        println(
          "Wrote JSON: " +
          path +
          " (" +
          records.length().to_string() +
          " records)",
        )
      } else {
        println("Unable to write file: " + path)
      }
  }
}

///|
fn convert_records_to_mrc(
  records : Array[@record.MarcRecord],
  output : String?,
) -> Unit {
  let encoded = match @iso2709.serialize_records(records) {
    Err(error) => {
      println("Unable to serialize MARC records: " + error.to_string())
      return
    }
    Ok(value) => value
  }
  match output {
    None => println("Conversion to MRC requires --output FILE")
    Some(path) =>
      if write_bytes(path, encoded) {
        println(
          "Wrote MARC: " +
          path +
          " (" +
          records.length().to_string() +
          " records)",
        )
      } else {
        println("Unable to write file: " + path)
      }
  }
}

///|
fn convert_mrc_to_xml(path : String, output : String?) -> Unit {
  let bytes = match read_input(path) {
    None => {
      println("Unable to read file: " + path)
      return
    }
    Some(value) => value
  }
  let parsed = @iso2709.parse_records(bytes)
  let records : Array[@record.MarcRecord] = []
  for index, result in parsed {
    match result {
      Err(error) => {
        println(
          "ERROR record=" + (index + 1).to_string() + "\n  " + error.to_string(),
        )
        return
      }
      Ok(record) => records.push(record)
    }
  }
  let text = match records.length() {
    1 => @marcxml.record_to_xml(records[0])
    _ => @marcxml.records_to_xml(records)
  }
  match output {
    None => println(text)
    Some(path) =>
      if write_text(path, text + "\n") {
        println(
          "Wrote MARCXML: " +
          path +
          " (" +
          records.length().to_string() +
          " records)",
        )
      } else {
        println("Unable to write file: " + path)
      }
  }
}

///|
fn convert_xml_to_mrc(path : String, output : String?) -> Unit {
  let text = match read_text(path) {
    None => {
      println("Unable to read file: " + path)
      return
    }
    Some(value) => value
  }
  let records = match @marcxml.records_from_xml(text) {
    Err(error) => {
      println("Invalid MARCXML: " + error.to_string())
      return
    }
    Ok(value) => value
  }
  convert_records_to_mrc(records, output)
}

///|
fn convert_json_to_mrc(path : String, output : String?) -> Unit {
  let text = match read_text(path) {
    None => {
      println("Unable to read file: " + path)
      return
    }
    Some(value) => value
  }
  let trimmed = text.trim().to_owned()
  let records = if trimmed.has_prefix("[") {
    match @marcjson.records_from_json_text(trimmed) {
      Err(error) => {
        println("Invalid JSON MARC records: " + error.to_string())
        return
      }
      Ok(value) => value
    }
  } else {
    match @marcjson.record_from_json_text(trimmed) {
      Err(error) => {
        println("Invalid JSON MARC record: " + error.to_string())
        return
      }
      Ok(value) => [value]
    }
  }
  convert_records_to_mrc(records, output)
}

///|
fn parse_file_records(
  path : String,
) -> Array[Result[@record.MarcRecord, @record.RecordError]]? {
  match read_input(path) {
    None => {
      println("Unable to read file: " + path)
      None
    }
    Some(bytes) => Some(@iso2709.parse_records(bytes))
  }
}

///|
fn privacy(path : String) -> Unit {
  let results = match parse_file_records(path) {
    None => return
    Some(value) => value
  }
  let records : Array[@record.MarcRecord] = []
  for index, result in results {
    match result {
      Err(error) =>
        println(
          "ERROR record=" + (index + 1).to_string() + "\n  " + error.to_string(),
        )
      Ok(record) => records.push(record)
    }
  }
  let report = @privacy.scan(records)
  println("Privacy scan")
  println("Records: " + report.records.to_string())
  println("Local fields: " + report.local_fields.to_string())
  println("Email-like values: " + report.email_values.to_string())
  println("Phone-like values: " + report.phone_values.to_string())
  if report.manual_review_required {
    println("Recommended action: manual review required")
  } else {
    println("Recommended action: no matches detected")
  }
}

///|
fn redact(path : String, args : Array[String]) -> Unit {
  let results = match parse_file_records(path) {
    None => return
    Some(value) => value
  }
  let records : Array[@record.MarcRecord] = []
  for index, result in results {
    match result {
      Err(error) => {
        println(
          "ERROR record=" + (index + 1).to_string() + "\n  " + error.to_string(),
        )
        return
      }
      Ok(record) => records.push(record)
    }
  }
  let output = match option_value(args, "--output") {
    None => {
      println("Redaction requires --output FILE")
      return
    }
    Some(value) => value
  }
  let redacted = @privacy.redact(
    records,
    drop_9xx=has_flag(args, "--drop-9xx"),
    mask_email=has_flag(args, "--mask-email"),
  )
  convert_records_to_mrc(redacted, Some(output))
}

///|
fn stats(path : String) -> Unit {
  let results = match parse_file_records(path) {
    None => return
    Some(value) => value
  }
  let summary = @stats.analyze(results)
  println("Dataset statistics")
  println("Records: " + summary.records.to_string())
  println("Valid: " + summary.valid.to_string())
  println("Errors: " + summary.errors.to_string())
  println("")
  println("Coverage:")
  println("  Title: " + summary.title_coverage.to_string() + ".00%")
  println("  Author: " + summary.author_coverage.to_string() + ".00%")
  println("  ISBN: " + summary.isbn_coverage.to_string() + ".00%")
  println("")
  println("Most common fields:")
  for index, item in summary.field_counts {
    if index >= 10 {
      break
    }
    println("  " + item.tag + ": " + item.count.to_string())
  }
}

///|
fn convert(path : String, args : Array[String]) -> Unit {
  let format = match option_value(args, "--format") {
    None => {
      println("Missing required option: --format json|mrc|marcxml")
      return
    }
    Some(value) => value
  }
  let output = option_value(args, "--output")
  match format {
    "json" => {
      let indent = match option_value(args, "--indent") {
        None => if has_flag(args, "--pretty") { Some(2) } else { None }
        Some(value) =>
          Some(@string.parse_int(value)) catch {
            _ => {
              println("Indent must be an integer: " + value)
              return
            }
          }
      }
      convert_mrc_to_json(path, output, indent)
    }
    "mrc" => {
      let text = match read_text(path) {
        None => {
          println("Unable to read file: " + path)
          return
        }
        Some(value) => value.trim().to_owned()
      }
      if text.has_prefix("<") {
        convert_xml_to_mrc(path, output)
      } else {
        convert_json_to_mrc(path, output)
      }
    }
    "marcxml" => convert_mrc_to_xml(path, output)
    _ =>
      println("Unsupported format: " + format + "; use json, marcxml, or mrc")
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
    "show" if args.length() >= 4 => {
      let index_text = if args[3] == "--record" && args.length() >= 5 {
        args[4]
      } else {
        args[3]
      }
      show(args[2], @string.parse_int(index_text)) catch {
        _ => println("Record index must be an integer: " + index_text)
      }
    }
    "query" if args.length() >= 4 => query(args[2], args[3])
    "privacy" if args.length() >= 3 => privacy(args[2])
    "redact" if args.length() >= 3 => redact(args[2], args)
    "stats" if args.length() >= 3 => stats(args[2])
    "convert" if args.length() >= 3 => convert(args[2], args)
    _ => print_usage()
  }
}
