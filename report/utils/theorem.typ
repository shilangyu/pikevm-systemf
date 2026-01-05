// TODO: do theorem referencing

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

#let theorem(name, body, supplement: "Theorem") = {
  show figure: set align(left)

  figure(
    // TODO: think of good formatting for names/body
    [#smallcaps(supplement) #name. #body],
    kind: "theorem",
    supplement: supplement,
  )
}
