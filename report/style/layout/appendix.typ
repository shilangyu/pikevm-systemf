#let appendix(bodies) = {
  set heading(numbering: "A", supplement: [Appendix])
  show heading: it => block[
    Appendix #counter(heading).display() -- #it.body
  ]
  counter(heading).update(0)
  for body in bodies {
    body
    pagebreak()
  }
}
