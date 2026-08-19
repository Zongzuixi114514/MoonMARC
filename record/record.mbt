///|
/// A MARC subfield.
pub(all) struct Subfield {
  code : Char
  value : String
} derive(Eq, Debug)

///|
/// A MARC control or data field.
pub(all) enum MarcField {
  ControlField(tag~ : String, value~ : String)
  DataField(
    tag~ : String,
    indicator1~ : Char,
    indicator2~ : Char,
    subfields~ : Array[Subfield]
  )
} derive(Eq, Debug)

///|
/// A parsed MARC 21 record.
pub(all) struct MarcRecord {
  leader : @leader.Leader
  fields : Array[MarcField]
} derive(Eq, Debug)

///|
pub fn MarcRecord::leader(self : MarcRecord) -> @leader.Leader {
  self.leader
}

///|
pub fn MarcRecord::fields(self : MarcRecord) -> Array[MarcField] {
  self.fields
}

///|
pub fn MarcField::tag(self : MarcField) -> String {
  match self {
    ControlField(tag~, ..) => tag
    DataField(tag~, ..) => tag
  }
}

///|
pub fn MarcField::value(self : MarcField) -> String {
  match self {
    ControlField(value~, ..) => value
    DataField(subfields~, ..) => {
      let mut output = ""
      for subfield in subfields {
        if output.is_empty() {
          output = subfield.value
        } else {
          output = output + " " + subfield.value
        }
      }
      output
    }
  }
}

///|
pub fn MarcRecord::fields_by_tag(
  self : MarcRecord,
  tag : String,
) -> Array[MarcField] {
  let result : Array[MarcField] = []
  for field in self.fields {
    if field.tag() == tag {
      result.push(field)
    }
  }
  result
}

///|
pub fn MarcRecord::first_subfield(
  self : MarcRecord,
  tag : String,
  code : Char,
) -> String? {
  for field in self.fields {
    match field {
      DataField(tag=field_tag, subfields~, ..) if field_tag == tag =>
        for subfield in subfields {
          if subfield.code == code {
            return Some(subfield.value)
          }
        }
      _ => ()
    }
  }
  None
}

///|
pub fn MarcRecord::title(self : MarcRecord) -> String? {
  self.first_subfield("245", 'a')
}

///|
pub fn MarcRecord::control_number(self : MarcRecord) -> String? {
  for field in self.fields {
    match field {
      ControlField(tag="001", value~) => return Some(value)
      _ => ()
    }
  }
  None
}

///|
/// Return every value of a subfield across all matching fields.
pub fn MarcRecord::subfields(
  self : MarcRecord,
  tag : String,
  code : Char,
) -> Array[String] {
  let result : Array[String] = []
  for field in self.fields {
    match field {
      DataField(tag=field_tag, subfields~, ..) if field_tag == tag =>
        for subfield in subfields {
          if subfield.code == code {
            result.push(subfield.value)
          }
        }
      _ => ()
    }
  }
  result
}

///|
pub fn MarcRecord::isbn_list(self : MarcRecord) -> Array[String] {
  self.subfields("020", 'a')
}

///|
pub fn MarcRecord::subtitle(self : MarcRecord) -> String? {
  self.first_subfield("245", 'b')
}

///|
pub fn MarcRecord::primary_author(self : MarcRecord) -> String? {
  self.first_subfield("100", 'a')
}

///|
pub fn MarcRecord::other_authors(self : MarcRecord) -> Array[String] {
  self.subfields("700", 'a')
}

///|
pub fn MarcRecord::publisher(self : MarcRecord) -> String? {
  self.first_subfield("264", 'b')
}

///|
pub fn MarcRecord::publication_year(self : MarcRecord) -> String? {
  self.first_subfield("264", 'c')
}

///|
pub fn MarcRecord::languages(self : MarcRecord) -> Array[String] {
  self.subfields("041", 'a')
}

///|
pub fn MarcRecord::subjects(self : MarcRecord) -> Array[String] {
  self.subfields("650", 'a')
}

///|
pub fn MarcRecord::summary(self : MarcRecord) -> String? {
  self.first_subfield("520", 'a')
}
