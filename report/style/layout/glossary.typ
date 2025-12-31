#let style = underline.with(stroke: (thickness: 1pt, dash: "loosely-dashed"))

#let capitalize(word) = {
  if word.len() == 0 {
    ""
  } else {
    upper(word.at(0)) + word.slice(1)
  }
}

#let decapitalize(word) = {
  if word.len() == 0 {
    ""
  } else {
    lower(word.at(0)) + word.slice(1)
  }
}

// TODO: add panic for unknown modifiers
#let format-with-modifiers(modifiers, entry) = {
  let cap(term) = if modifiers.contains("cap") { capitalize(term) } else { decapitalize(term) }
  let short = if modifiers.contains("plural") { decapitalize(entry.shortPlural) } else { decapitalize(entry.short) }
  let long = if modifiers.contains("plural") { decapitalize(entry.longPlural) } else { decapitalize(entry.long) }

  if modifiers.contains("intro") {
    [#cap(long) (#short)]
  } else {
    cap(entry.short)
  }
}

#let glossary-ref-format(entries) = it => {
  let parts = str(it.target).split(":")
  if parts.at(0) in entries.keys() {
    link(label(parts.at(0)))[#style[#format-with-modifiers(parts.slice(1), entries.at(parts.at(0)))]]
  } else {
    it
  }
}


#let glossary-table(entries) = [
  #heading(numbering: none)[#style[Glossary]]

  #table(
    columns: (auto, 1fr, 2fr),
    [*Term*], [*Full name*], [*Description*],
    ..for (key, value) in entries.pairs().sorted(key: ((_, v)) => v.short) {
      (
        [#table.cell[#value.short] #label(key)],
        value.long,
        value.description,
      )
    },
  )
]
