#import "/style/layout/title-page.typ": *
#import "/style/syntax.typ": *
#import "/style/layout/acknowledgement.typ": *
#import "/style/layout/appendix.typ": appendix as appendix_layout
#import "/style/layout/abstract.typ": abstract as abstract_layout
#import "/style/fonts.typ": *


// The main thesis layout bootstrapper.

#let thesis(
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
  abstract: "",
  abstractFrench: "",
  acknowledgements: "",
  appendix: "",
  body,
) = {
  title-page(
    title: title,
    titleFrench: titleFrench,
    degree: degree,
    program: program,
    specialization: specialization,
    school: school,
    examiner: examiner,
    supervisors: supervisors,
    author: author,
    startDate: startDate,
    submissionDate: submissionDate,
  )

  pagebreak()

  acknowledgement(acknowledgements)

  pagebreak()

  abstract_layout(lang: "en")[#abstract]
  abstract_layout(lang: "fr")[#abstractFrench]

  set page(
    margin: (left: 30mm, right: 30mm, top: 40mm, bottom: 40mm),
    numbering: none,
    number-align: center,
  )

  set text(
    font: fonts.body,
    size: 12pt,
    lang: "en",
  )

  show math.equation: set text(weight: 400)
  show raw: set text(font: fonts.mono)
  show: set raw(syntaxes: syntaxes)

  // --- Headings ---
  show heading: set block(below: 0.85em, above: 1.75em)
  show heading: set text(font: fonts.body)
  set heading(numbering: "1.1")
  // Reference first-level headings as "chapters"
  show ref: it => {
    let el = it.element
    if el != none and el.func() == heading and el.level == 1 {
      link(
        el.location(),
        [Chapter #numbering(el.numbering, ..counter(heading).at(el.location()))],
      )
    } else {
      it
    }
  }

  // --- Paragraphs ---
  set par(leading: 1em)

  // --- Citations ---
  set cite(style: "alphanumeric")

  // --- Figures ---
  show figure: set text(size: 0.85em)

  // --- Table of Contents ---
  show outline.entry.where(level: 1): it => {
    v(15pt, weak: true)
    strong(it)
  }
  outline(
    title: {
      text(font: fonts.body, 1.5em, weight: 700, "Contents")
      v(15mm)
    },
    indent: 2em,
  )


  v(2.4fr)
  pagebreak()


  // Main body. Reset page numbering.
  set page(numbering: "1")
  counter(page).update(1)
  set par(justify: true, first-line-indent: 2em)

  body

  // List of figures.
  pagebreak()
  heading(numbering: none)[List of Figures]
  outline(
    title: "",
    target: figure.where(kind: image),
  )

  // List of tables.
  context [
    #if query(figure.where(kind: table)).len() > 0 {
      pagebreak()
      heading(numbering: none)[List of Tables]
      outline(
        title: "",
        target: figure.where(kind: table),
      )
    }
  ]

  // Appendix.
  pagebreak()
  appendix_layout(appendix)

  bibliography("/bibliography.yml")
}
