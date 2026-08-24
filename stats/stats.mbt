///|
pub(all) struct FieldCount {
  tag : String
  count : Int
} derive(Eq, Debug)

///|
pub(all) struct DatasetStats {
  records : Int
  valid : Int
  errors : Int
  title_coverage : Int
  author_coverage : Int
  isbn_coverage : Int
  field_counts : Array[FieldCount]
} derive(Eq, Debug)

///|
fn add_field_count(counts : Array[FieldCount], tag : String) -> Unit {
  for index, item in counts {
    if item.tag == tag {
      counts[index] = { tag, count: item.count + 1 }
      return
    }
  }
  counts.push({ tag, count: 1 })
}

///|
fn sort_counts(counts : Array[FieldCount]) -> Array[FieldCount] {
  let output = counts.copy()
  let mut i = 0
  while i < output.length() {
    let mut j = i + 1
    while j < output.length() {
      if output[j].count > output[i].count ||
        (output[j].count == output[i].count && output[j].tag < output[i].tag) {
        let item = output[i]
        output[i] = output[j]
        output[j] = item
      }
      j = j + 1
    }
    i = i + 1
  }
  output
}

///|
fn percentage(part : Int, whole : Int) -> Int {
  if whole == 0 {
    0
  } else {
    part * 100 / whole
  }
}

///|
pub fn analyze(
  results : Array[Result[@record.MarcRecord, @record.RecordError]],
) -> DatasetStats {
  let mut valid = 0
  let mut errors = 0
  let mut titles = 0
  let mut authors = 0
  let mut isbns = 0
  let counts : Array[FieldCount] = []
  for result in results {
    match result {
      Err(_) => errors = errors + 1
      Ok(record) => {
        valid = valid + 1
        if record.title() is Some(_) {
          titles = titles + 1
        }
        if record.primary_author() is Some(_) {
          authors = authors + 1
        }
        if record.isbn_list().length() > 0 {
          isbns = isbns + 1
        }
        for field in record.fields() {
          add_field_count(counts, field.tag())
        }
      }
    }
  }
  {
    records: results.length(),
    valid,
    errors,
    title_coverage: percentage(titles, valid),
    author_coverage: percentage(authors, valid),
    isbn_coverage: percentage(isbns, valid),
    field_counts: sort_counts(counts),
  }
}
