#let appendix(body) = {
  set heading(numbering: "A", supplement: [Appendix])
  show heading.where(level: 1): it => [
    #pagebreak(weak: true)
    #block[Appendix #counter(heading).display() -- #it.body]
  ]
  counter(heading).update(0)
  body
}
