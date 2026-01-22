#import "/style/thesis.typ": *
#import "/metadata.typ": *
#import "prelude.typ": catppuccin.catppuccin

#set document(title: title, author: author)

#show: catppuccin.with(flavor)

#TODO-outline

// don't allow regexes to be broken across pages/lines
#show raw.where(lang: "re"): box

#show raw.where(lang: "re"): it => {
  assert-no-similar-letters(it.text)
  it
}

#show: thesis.with(
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
  abstract: include "/content/abstract.typ",
  preface: include "/content/preface.typ",
  glossary: glossary,
)

#NOTE[
  - When referencing a heading, use the heading number and put the heading titles in the margin
  - When referencing an glossary intro, add definition to the margin
]

#NOTE[
  - explain one rule of the pikevm, refer to the original paper for info
  - explain backtracking trees, show one rule dot star

  - related work:
    - several attempts of formalizing but they omit this and that
    - a work of formalizing pikevm with some sort of prefix acc
]

#TODO[The title page does not look good]
#TODO[Make sure the outline fits on one page]

#NOTE[
  From Aurèle's review:

  3) "Linden provides a complete and practical mechanization of the ECMAScript 2023" maybe you could be a bit more precise, and introduce Warblre as well. Say that Linden is complete and practical, and that it has been proved equivalent to Warblre, a faithful mechanization of ECMAScript 2023. Also in that sentence, you should be clear that it is only the regex chapter of ECMAScript, not the whole thing.

  Future work) you might be missing the optimization that Clément described, where in some cases we could start new PikeVM threads not in the initial state, but in some later state correpsonding to after having read the prefix. This avoids some redundant reads when the prefix is quite long. -> short description
]

#include "/content/introduction.typ"
#include "/content/background/background.typ"
#include "/content/chapters/chapters.typ"
#include "/content/evaluation.typ"
#include "/content/discussion.typ"
