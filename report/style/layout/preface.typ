#import "/style/fonts.typ": *

#let preface(body) = {
  set page(
    margin: (left: 30mm, right: 30mm, top: 30mm, bottom: 30mm),
    numbering: none,
  )

  set text(
    font: fonts.body,
    size: 12pt,
    lang: "en",
  )

  set par(
    leading: 1em,
    justify: true,
  )

  heading(level: 1, outlined: false, text(font: fonts.sans, 1.5em, weight: 700, "Preface"))
  v(5mm)

  body
}
