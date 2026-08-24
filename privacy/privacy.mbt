///|
pub(all) struct PrivacyReport {
  records : Int
  local_fields : Int
  email_values : Int
  phone_values : Int
  manual_review_required : Bool
} derive(Eq, Debug)

///|
fn contains_email(value : String) -> Bool {
  value.contains("@") && value.contains(".")
}

///|
fn digit_count(value : String) -> Int {
  let mut count = 0
  for character in value {
    if character >= '0' && character <= '9' {
      count = count + 1
    }
  }
  count
}

///|
fn contains_phone(value : String) -> Bool {
  digit_count(value) >= 7
}

///|
fn field_values(field : @record.MarcField) -> Array[String] {
  match field {
    @record.MarcField::ControlField(value~, ..) => [value]
    @record.MarcField::DataField(subfields~, ..) => {
      let values : Array[String] = []
      for subfield in subfields {
        values.push(subfield.value)
      }
      values
    }
  }
}

///|
pub fn scan(records : Array[@record.MarcRecord]) -> PrivacyReport {
  let mut local_fields = 0
  let mut email_values = 0
  let mut phone_values = 0
  for record in records {
    for field in record.fields() {
      if field.tag() >= "900" && field.tag() <= "999" {
        local_fields = local_fields + 1
      }
      for value in field_values(field) {
        if contains_email(value) {
          email_values = email_values + 1
        }
        if contains_phone(value) {
          phone_values = phone_values + 1
        }
      }
    }
  }
  {
    records: records.length(),
    local_fields,
    email_values,
    phone_values,
    manual_review_required: local_fields > 0 ||
    email_values > 0 ||
    phone_values > 0,
  }
}

///|
fn mask_email(value : String) -> String {
  match value.find("@") {
    None => value
    Some(position) => "***" + value[position:].to_owned()
  }
}

///|
fn redact_field(
  field : @record.MarcField,
  drop_9xx : Bool,
  mask_email_values : Bool,
) -> @record.MarcField? {
  if drop_9xx && field.tag() >= "900" && field.tag() <= "999" {
    return None
  }
  match field {
    @record.MarcField::ControlField(tag~, value~) =>
      Some(
        @record.MarcField::ControlField(
          tag~,
          value=if mask_email_values && contains_email(value) {
            mask_email(value)
          } else {
            value
          },
        ),
      )
    @record.MarcField::DataField(tag~, indicator1~, indicator2~, subfields~) => {
      let updated : Array[@record.Subfield] = []
      for subfield in subfields {
        updated.push({
          code: subfield.code,
          value: if mask_email_values && contains_email(subfield.value) {
            mask_email(subfield.value)
          } else {
            subfield.value
          },
        })
      }
      Some(
        @record.MarcField::DataField(
          tag~,
          indicator1~,
          indicator2~,
          subfields=updated,
        ),
      )
    }
  }
}

///|
pub fn redact(
  records : Array[@record.MarcRecord],
  drop_9xx? : Bool,
  mask_email? : Bool,
) -> Array[@record.MarcRecord] {
  let drop_9xx = match drop_9xx {
    None => false
    Some(value) => value
  }
  let mask_email_values = match mask_email {
    None => false
    Some(value) => value
  }
  let output : Array[@record.MarcRecord] = []
  for record in records {
    let fields : Array[@record.MarcField] = []
    for field in record.fields() {
      match redact_field(field, drop_9xx, mask_email_values) {
        None => ()
        Some(value) => fields.push(value)
      }
    }
    output.push({ leader: record.leader(), fields })
  }
  output
}
