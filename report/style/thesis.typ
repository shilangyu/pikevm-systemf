#import "/style/layout/title-page.typ": *
#import "/style/syntax.typ": *
#import "/style/layout/acknowledgement.typ": *
#import "/style/layout/appendix.typ": appendix as appendix-layout
#import "/style/layout/abstract.typ": abstract as abstract-layout
#import "/style/layout/glossary.typ": *
#import "/style/fonts.typ": *
#import "/style/colors.typ": *
#import "/prelude.typ": *

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
  glossary: dictionary,
  appendix: "",
  body,
) = {
  show: setup-theorems
  show: glossary-setup.with(glossary)
  // Links which link within the document have this style
  let document-link-style = underline.with(stroke: (thickness: 1pt, dash: "loosely-dotted"))
  show link: it => {
    if type(it.dest) == str {
      text(external-link-color)[#it]
    } else {
      document-link-style(it)
    }
  }
  show ref: document-link-style


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

  abstract-layout(lang: "en")[#abstract]
  abstract-layout(lang: "fr")[#abstractFrench]

  pagebreak()

  acknowledgement(acknowledgements)

  set page(
    numbering: none,
    // TODO: alternate pages between left/right align
    number-align: center,
  )

  show: marginalia.setup.with(
    inner: (width: 7mm),
    outer: (width: 40mm),
    book: book,
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
  show figure: set text(size: 0.8em)
  show figure.caption.where(position: bottom): note.with(
    alignment: "bottom",
    counter: none,
    shift: "avoid",
    keep-order: true,
  )
  show figure.caption.where(position: top): note.with(
    alignment: "top",
    counter: none,
    shift: "avoid",
    keep-order: true,
    dy: -0.01pt, // this is so that the caption is placed above wide figures.
  )

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

  bibliography("/bibliography.yml")

  glossary-table(glossary)

  // Appendix.
  pagebreak()
  appendix-layout(appendix)
}
