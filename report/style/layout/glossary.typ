// TODO: when doing @term:intro, put the definition in the margin

#let style = underline.with(stroke: (thickness: 1pt, dash: "loosely-dotted"))

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
  let short = if modifiers.contains("plural") { entry.shortPlural } else { entry.short }
  let long = if modifiers.contains("plural") { entry.longPlural } else { entry.long }

  if modifiers.contains("intro") {
    if long == short {
      cap(long)
    } else {
      [#cap(long) (#short)]
    }
  } else if modifiers.contains("long") {
    cap(long)
  } else {
    cap(short)
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
        [#table.cell[#capitalize(value.short)] #label(key)],
        capitalize(value.long),
        value.description,
      )
    },
  )
]
