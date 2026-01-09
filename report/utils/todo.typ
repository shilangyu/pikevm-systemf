#import "/packages.typ": colorful-boxes.stickybox, marginalia
#import "/style/fonts.typ": *

#let todos = state("todos", ())

#let todo-color = orange

#let note = marginalia.note.with(
  numbering: marginalia.note-numbering.with(
    style: text.with(weight: 900, font: fonts.sans, size: 5pt, style: "normal", fill: rgb(54%, 72%, 95%)),
  ),
)

#let to-str(v) = {
  if type(v) == content and v.func() == text {
    v.text
  } else if type(v) == int or type(v) == float or type(v) == str or type(v) == bool {
    str(v)
  } else {
    "???"
  }
}

#let TODO(body, ..kwargs) = {
  let (doc, msg) = if kwargs.pos().len() > 0 {
    (body, kwargs.pos().at(0))
  } else {
    (none, body)
  }

  context {
    let loc = here()
    todos.update(e => (..e, (msg: to-str(msg), loc: loc)))
  }

  set text(todo-color)
  doc
  note(msg)
}

#let NOTE(body) = {
  context {
    let loc = here()
    todos.update(e => (..e, (msg: to-str(body), loc: loc)))
  }

  stickybox(rotation: 3deg, width: 100%, body)
}

#let TODO-outline = context [
  = TODOs

  #for (msg, loc) in todos.final() [
    - #link(loc, text(todo-color, msg)) #box(width: 1fr, repeat[.]) #{ loc.page() }
  ]
]
