#import "/style/thesis.typ": *
#import "/metadata.typ": *
#import "/content/glossary.typ": glossary
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


#include "/content/introduction.typ"
#include "/content/background/background.typ"
#include "/content/chapters/chapters.typ"
#include "/content/evaluation.typ"
#include "/content/discussion.typ"
