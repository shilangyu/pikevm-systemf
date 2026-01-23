#import "/style/fonts.typ": *

#let title-page(
  title: "",
  degree: "",
  program: "",
  specialization: "",
  school: "",
  examiner: "",
  supervisors: (),
  author: "",
  start-date: datetime,
  submission-date: datetime,
) = {
  assert(
    degree in ("Bachelor", "Master"),
    message: "The degree must be either 'Bachelor' or 'Master'",
  )

  set page(
    margin: (left: 20mm, right: 20mm, top: 30mm, bottom: 30mm),
    numbering: none,
    number-align: center,
  )

  set text(
    font: fonts.body,
    size: 12pt,
    lang: "en",
  )

  set par(leading: 0.5em)

  align(center, image("/figures/EPFL_logo.pdf", width: 26%))

  v(5mm)
  align(center, text(
    font: fonts.sans,
    2em,
    weight: 700,
    "École Polytechnique Fédérale de Lausanne",
  ))

  align(center, text(
    font: fonts.sans,
    1.5em,
    weight: 100,
    school,
  ))

  align(center, image("/figures/SYSTEMF_logo.svg", width: 26%))

  v(1fr)

  align(center, text(font: fonts.sans, 2em, weight: 700, title))
  align(center, text(
    font: fonts.sans,
    1.3em,
    weight: 100,
    degree + "'s Thesis in " + program + "\n(" + specialization + ")",
  ))

  v(1fr)

  let entries = ()
  entries.push(("Author", author))
  // Only show supervisors if there are any
  if supervisors.len() > 0 {
    let supervisor-field = "Supervisor" + if supervisors.len() > 1 [s]
    entries.push((supervisor-field, supervisors.join(", ")))
  }
  entries.push(("Examiner", examiner))
  entries.push(("Start Date", start-date.display("[day].[month].[year]")))
  entries.push((
    "Submission Date",
    submission-date.display("[day].[month].[year]"),
  ))

  align(
    center,
    grid(
      columns: 2,
      gutter: 1em,
      align: left,
      ..for (term, desc) in entries {
        ([*#term:*], desc)
      }
    ),
  )
}
