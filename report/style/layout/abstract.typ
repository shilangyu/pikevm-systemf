#import "/style/fonts.typ": *

#let abstract(body) = {
  set text(
    font: fonts.body,
    size: 12pt,
  )

  set par(
    leading: 1em,
    justify: true,
  )

  v(1fr)
  align(center, text(font: fonts.body, 1em, weight: "semibold", "Abstract"))

  body

  v(1fr)
}
