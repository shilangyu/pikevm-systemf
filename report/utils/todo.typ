#import "@preview/drafting:0.2.2": *
#import "@preview/colorful-boxes:1.4.3": stickybox

#let sticky-box(stroke: none, fill: none, width: 100%, content) = {
  stickybox(rotation: 3deg, width: width, content)
}

#let TODO(body, ..kwargs) = {
  if kwargs.pos().len() > 0 {
    margin-note(body, text(kwargs.pos().at(0), size: 0.6em), stroke: orange + 2pt)
  } else {
    margin-note(text(body, size: 0.6em), stroke: orange + 2pt)
  }
}
#let NOTE = inline-note.with(rect: sticky-box, stroke: none)

#let TODO-outline = note-outline.with(title: "TODOs")
