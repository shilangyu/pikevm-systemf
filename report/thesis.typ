#import "/style/thesis.typ": *
#import "/metadata.typ": *
#import "prelude.typ": catppuccin.catppuccin, catppuccin.flavors

#set document(title: titleEnglish, author: author)

#show: catppuccin.with(flavors.latte)

#TODO-outline()

#show raw.where(lang: "regex"): it => {
  if it.block {
    it
  } else {
    box[/#it/]
  }
}

#show: thesis.with(
  title: titleEnglish,
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
  abstract: include "/content/abstract.typ",
  abstractFrench: include "/content/abstract_french.typ",
  acknowledgements: include "/content/acknowledgements.typ",
  glossary: glossary,
  appendix: include "/content/appendixes/appendixes.typ",
)

#NOTE[
  make left/right margins depend on the page parity
  - Things like figures should be able to use all of the space
]

#NOTE[Appendix reference does not use the "Appendix" supplement]

#NOTE[
  - Try to integrate tree-sitter for syntax highlighting (https://github.com/RubixDev/syntastica-typst and https://zed.dev/blog/language-extensions-part-1)
  - Rocq syntax highlighting
  - Investigate how official is the Typst LSP. Issues with it:
    - Bullet points do not get auto completed (this should be done with the https://github.com/rust-lang/rust-analyzer/blob/master/docs/dev/lsp-extensions.md#on-enter event)
    - No autoimport
]

#include "/content/introduction.typ"
#include "/content/background/background.typ"
#include "/content/chapters/chapters.typ"
#include "/content/evaluation.typ"
#include "/content/related_work.typ"
#include "/content/summary.typ"
