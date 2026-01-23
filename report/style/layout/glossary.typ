#let capitalize(word) = {
  if word.len() == 0 {
    ""
  } else {
    upper(word.at(0)) + word.slice(1)
  }
}

// TODO: add panic for unknown modifiers
#let format-with-modifiers(modifiers, entry) = {
  let cap(term) = if modifiers.contains("cap") { capitalize(term) } else { term }
  let short = if modifiers.contains("plural") { entry.short-plural } else { entry.short }
  let long = if modifiers.contains("plural") { entry.long-plural } else { entry.long }

  if modifiers.contains("intro") {
    if long == short {
      cap(long)
    } else [#cap(long) (#short)]
  } else if modifiers.contains("long") {
    cap(long)
  } else {
    cap(short)
  }
}

#let glossary-setup(entries, body) = {
  show ref: it => {
    let parts = str(it.target).split(":")
    if parts.at(0) in entries.keys() {
      link(label(parts.at(0)))[#format-with-modifiers(parts.slice(1), entries.at(parts.at(0)))]
    } else {
      it
    }
  }
  body
}


#let glossary-table(entries) = [
  #heading(numbering: none)[Glossary]

  #for (key, value) in entries.pairs().sorted(key: ((_, v)) => lower(v.short)) [
    #let long = if value.long == value.short { "" } else { " (" + capitalize(value.long) + ")" }
    / #capitalize(value.short) #long #label(key): #value.description
  ]
]
