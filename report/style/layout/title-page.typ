#import "/style/fonts.typ": *

#let title-page(
  title: "",
  titleFrench: "",
  degree: "",
  program: "",
  specialization: "",
  school: "",
  examiner: "",
  supervisors: (),
  author: "",
  startDate: datetime,
  submissionDate: datetime,
) = {
  let title-table(entries) = {
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

  assert(degree in ("Bachelor", "Master"), message: "The degree must be either 'Bachelor' or 'Master'")

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

  v(1cm)
  align(center, image("/figures/EPFL_logo.png", width: 26%))

  v(5mm)
  align(center, text(font: fonts.sans, 2em, weight: 700, "École Polytechnique Fédérale de Lausanne"))

  v(5mm)
  align(center, text(
    font: fonts.sans,
    1.5em,
    weight: 100,
    school,
  ))

  v(15mm)

  align(center, text(
    font: fonts.sans,
    1.3em,
    weight: 100,
    degree + "'s Thesis in " + program + "\n(" + specialization + ")",
  ))

  v(8mm)


  align(center, text(font: fonts.sans, 2em, weight: 700, title))
  align(center, text(font: fonts.sans, 2em, weight: 500, titleFrench))

  let entries = ()
  entries.push(("Author", author))
  entries.push(("Examiner", examiner))
  // Only show supervisors if there are any
  if supervisors.len() > 0 {
    let supervisorField = "Supervisor" + if supervisors.len() > 1 [s]
    entries.push((supervisorField, supervisors.join(", ")))
  }
  entries.push(("Start Date", startDate.display("[day].[month].[year]")))
  entries.push(("Submission Date", submissionDate.display("[day].[month].[year]")))

  v(1cm)
  title-table(entries)
}
