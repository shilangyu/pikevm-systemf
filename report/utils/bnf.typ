// Based on https://github.com/Zeta611/simplebnf.typ

#let bnf(
  ..body,
) = {
  set par(justify: false)

  let content = body.pos().intersperse((none,) * 4).flatten()

  table(
    columns: (
      auto,
      auto,
      1fr,
      auto,
    ),
    align: (
      center,
      center,
      left,
      left,
    ),
    inset: 0.28em,
    stroke: none,
    ..content,
  )
}

#let Prod(
  lhs,
  ..rhs,
) = {
  let pad = (
    none,
    $|$,
  )
  let rhses = rhs.pos().flatten().chunks(2).intersperse(pad)
  (
    lhs,
    $::=$,
    rhses,
  )
}

#let Or(
  ..vars,
  annot,
) = (
  (
    box(vars.at(0)),
    ..for v in vars.pos().slice(1) {
      (box("|" + h(0.4em) + v),)
    },
  )
    .intersperse(h(0.4em))
    .join(),
  annot,
)
