#let capitalize(word) = {
  if word.len() == 0 {
    ""
  } else {
    upper(word.at(0)) + word.slice(1)
  }
}

#let get-format-modifiers(modifiers) = {
  let map = (
    intro: "intro" in modifiers,
    cap: "cap" in modifiers,
    plural: "plural" in modifiers,
    long: "long" in modifiers,
  )

  // there should be no other unknown modifiers
  assert(modifiers.all(mod => mod in map.keys()), message: "Used some unknown glossary modifier: " + repr(modifiers))

  map
}

#let format-with-modifiers(modifiers, entry) = {
  let cap(term) = if modifiers.cap { capitalize(term) } else { term }
  let short = if modifiers.plural { entry.short-plural } else { entry.short }
  let long = if modifiers.plural { entry.long-plural } else { entry.long }

  if modifiers.intro {
    if long == short {
      cap(long)
    } else [#cap(long) (#short)]
  } else if modifiers.long {
    cap(long)
  } else {
    cap(short)
  }
}

#let glossary-setup(entries, body) = {
  show ref: it => {
    let parts = str(it.target).split(":")
    if parts.at(0) in entries.keys() {
      let modifiers = get-format-modifiers(parts.slice(1))
      let entry = entries.at(parts.at(0))

      link(label(parts.at(0)), format-with-modifiers(modifiers, entry))
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
