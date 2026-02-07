#import "/style/layout/title-page.typ": *
#import "/style/syntax.typ": *
#import "/style/layout/preface.typ": preface as preface-layout
#import "/style/layout/abstract.typ": abstract as abstract-layout
#import "/style/layout/glossary.typ": *
#import "/style/fonts.typ": *
#import "/style/colors.typ": *
#import "/prelude.typ": *

// The main thesis layout bootstrapper.

#let thesis(
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
  abstract: "",
  preface: "",
  glossary: dictionary,
  body,
) = {
  let a4-width = 210mm
  set page(
    width: a4-width,
    height: a4-width
      * if book {
        1
      } else {
        calc.sqrt(2)
      },
    margin: (top: 20mm, bottom: 20mm),
  )

  set text(
    font: fonts.body,
    size: 12pt,
    lang: "en",
  )
  show math.equation: set text(weight: 400)
  show raw: set text(font: fonts.mono)
  set raw(syntaxes: syntaxes)

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

  show: glossary-setup.with(glossary)
  show: setup-theorems

  // Resize text in code blocks to avoid line breaks
  show raw.where(block: true): it => layout(size => {
    context {
      let current-size = text.size
      let width = measure(it).width
      let factor = if width > size.width {
        size.width / width * 100%
      } else {
        100%
      }
      let new-size = factor * current-size
      // Let's not go below some minimum size for readability
      let clamped-size = calc.max(new-size.to-absolute(), 7pt)

      set text(size: clamped-size)
      it
    }
  })

  title-page(
    title: title,
    degree: degree,
    program: program,
    specialization: specialization,
    school: school,
    examiner: examiner,
    supervisors: supervisors,
    author: author,
    start-date: start-date,
    submission-date: submission-date,
  )

  pagebreak()
  if book { pagebreak() }

  abstract-layout(abstract)

  pagebreak()
  if book { pagebreak() }

  preface-layout(preface)

  // --- Table of Contents ---
  show outline.entry.where(level: 1): it => {
    v(if book { 0.65em } else { 1.5em }, weak: true)
    strong(it)
  }
  show outline.entry: set block(spacing: if book { 0.4em } else { 0.8em })
  outline(
    title: {
      text(1.5em, weight: 700)[Contents]
      v(if book { 0.5em } else { 1em })
    },
    indent: 2em,
  )

  pagebreak()
  if book { pagebreak() }

  set page(
    numbering: none,
    footer: if book {
      context if here().page() > 1 {
        let outer-padding = page.margin.bottom - 1em - marginalia._config.get().outer.far
        marginalia.header(
          if calc.odd(here().page()) {
            set align(right)
            counter(page).display("1")
            h(outer-padding)
          } else {
            set align(left)
            h(outer-padding)
            counter(page).display("1")
          },
        )
      }
    } else { auto },
  )
  show: marginalia.setup.with(
    inner: (width: 7mm),
    outer: (width: 40mm),
    book: book,
  )

  // --- Headings ---
  show heading: set block(below: 0.85em, above: 1.75em)
  show heading: set text(font: fonts.body)
  show heading.where(level: 1): set text(size: 20pt, weight: 700)
  show heading.where(level: 4): set heading(outlined: false)
  show heading.where(level: 4): it => {
    set text(weight: 600)
    it.body
    [.]
  }
  set heading(numbering: "1.1")
  // Reference first-level headings as "chapters"
  // Reference fourth-level headings with their name
  show ref: it => {
    let el = it.element
    if el != none and el.func() == heading {
      if el.level == 1 {
        link(
          el.location(),
          [Chapter #numbering(el.numbering, ..counter(heading).at(el.location()))],
        )
      } else if el.level == 4 {
        link(
          el.location(),
          [Section #numbering(el.numbering, ..counter(heading).at(el.location()).slice(0, 2)) #el.body],
        )
      } else {
        it
      }
    } else {
      it
    }
  }
  // First-level headings start on odd pages in book mode
  show heading.where(level: 1): it => context {
    pagebreak(to: "odd", weak: true)
    it
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

  // Main body. Reset page numbering.
  set page(numbering: "1")
  counter(page).update(1)
  set par(justify: true, first-line-indent: 2em)

  body

  bibliography("/bibliography.yml")

  glossary-table(glossary)
}
