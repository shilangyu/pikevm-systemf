#let setup-theorems(body) = {
  show ref: it => {
    if (
      it.has("element")
        and it.element != none
        and it.element.has("children")
        and it.element.children.len() > 1
        and it.element.children.first().func() == metadata
        and it.element.children.first().value == "theorem"
    ) {
      let meta = it.element.children.at(1)
      let (name, supplement) = meta.value

      link(it.element.location(), supplement + " " + name)
    } else {
      it
    }
  }

  body
}

#let theorem(name, body, proof: none, supplement: "Theorem") = {
  metadata("theorem")
  metadata((name, supplement))
  show figure: set align(left)

  figure(
    [#smallcaps(supplement) (#name)#body],
    kind: "theorem",
    supplement: supplement,
  )

  {
    // This makes the styling of the proof the same as the one used in a figure
    show figure: _ => if proof != none {
      [*Proof.* #proof]
    }
    figure(none)
  }
}

#let definition(name, body) = theorem(name, [: ] + body, supplement: "Definition")
