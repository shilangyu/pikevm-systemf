// TODO: add back numbering of theorems.
#let thm-counter = counter("theorem")

// At the moment I disabled theorem numbering. I find that referencing theorems by their names makes much more sense. Code left in case I change my mind.
#let thm-counter-step() = context {
  let parent = counter(heading).get()
  let current = thm-counter.get()

  let new-value = if parent == current.slice(0, -1) {
    (..parent, current.last() + 1)
  } else {
    (..parent, 1)
  }

  thm-counter.update(new-value)
}

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
      // TODO: referencing should use the theorem number and put the name in the margin

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
    {
      [#smallcaps(supplement) (#name)#body]
      if proof != none {
        block[*Proof.* #proof]
      }
    },
    kind: "theorem",
    supplement: supplement,
  )
}
