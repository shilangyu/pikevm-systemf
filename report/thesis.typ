#import "/style/thesis.typ": *
#import "/metadata.typ": *
#import "prelude.typ": catppuccin.catppuccin

#set document(title: title-english, author: author)

#show: catppuccin.with(flavor)

#TODO-outline

// don't allow regexes to be broken across pages/lines
#show raw.where(lang: "re"): box

#show: thesis.with(
  title: title-english,
  title-french: title-french,
  degree: degree,
  program: program,
  specialization: specialization,
  school: school,
  examiner: examiner,
  supervisors: supervisors,
  author: author,
  start-date: start-date,
  submission-date: submission-date,
  abstract: include "/content/abstract.typ",
  abstract-french: include "/content/abstract_french.typ",
  acknowledgements: include "/content/acknowledgements.typ",
  glossary: glossary,
  appendix: include "/content/appendixes/appendixes.typ",
)

#NOTE[
  - When referencing a heading, use the heading number and put the heading titles in the margin
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
#include "/content/discussion.typ"
