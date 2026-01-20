#import "/style/thesis.typ": *
#import "/metadata.typ": *
#import "prelude.typ": catppuccin.catppuccin

#set document(title: title-english, author: author)

#show: catppuccin.with(flavor)

#TODO-outline

// don't allow regexes to be broken across pages/lines
#show raw.where(lang: "re"): box

#show raw.where(lang: "re"): it => {
  assert-no-similar-letters(it.text)
  it
}

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
  preface: include "/content/preface.typ",
  glossary: glossary,
  appendix: include "/content/appendixes/appendixes.typ",
)

#NOTE[
  - When referencing a heading, use the heading number and put the heading titles in the margin
  - When referencing an glossary intro, add definition to the margin
]

#TODO[Make glossary less ugly]

#NOTE[Appendix reference does not use the "Appendix" supplement]

#NOTE[Merge RegElk into main]

#NOTE[
  From Aurèle's review:

  Maybe one high-level criticism is that, while everything is nicely explained, we sometimes don't understand why we're reading about some things. The motivation behind some sections could be put forward.

  2. Background

    - "which means it should repeat" you might be missing some introduction to backtracking semantics and priority
    - I like the regex size section, but I'm not sure we understand why it is defined here


  3. Literal Extraction

    - I feel like the "neighborhood" discussion before the "must start" discussion might be too general. Why are you not directly starting from the "must start" discussion?
    - "search procedures. For this " capitalization
    - when talking about backreference literals: "this bound is important to preserve the linear". This is a bit surprising, you say that you don't want to be too precise for backreferences. And the reason is that being too precise would invalidate linear matching. But linear matching is not available for backreferences anyway. There should be a way to rephrase this. (Technically, the literal size proofs could be done assuming we don't have backreferences. Let's not do that right now of course, but let's rephrase these sentences.)
    - You could skip the three lemmas like "Lemma (brute_force_str_search_starts_with)" because we've already seen the typeclass in listing 9.
    - "We now prove that the extracted literals gives us some useful information about the matches of a regex." I disagree with useful. An analysis returning (Prefix empty) would be correct according to your proofs, but not useful. I would simply say that you prove that your literal extraction analysis returns correct results.
    - Similarly, "The properties which we care about are those which will allow us to accelerate regex matching" could be rephrased. Maybe a simple "A correct analaysis should exhibit the following properties, that we will use to prove the correctness of prefix acceleration" could work.
    - "if we do not generalize [...] we will get stuck" -> I suggest simplifying to "we need to generalize..."

  4. Prefix acceleration of the PikeVM

    - "Approaching the specification of how matching works from the angle anchored matching gives rise to cleaner semantics hence why these serve as the basis of formalization" I think this sentence could be confusing. At that point, a reader does not know that you can encode unanchored using anchored so the reader might not understand why these "serve as the basis", it feels like we forgot to address one issue. I would start by saying that we can encode unanchored with anchored, then say that this explains why the basis is anchored semantics.
    - " in isolation, prefix acceleration is also linear" what does that mean exactly? You mean more than just a substring search? Also linear for what?
    - "We start by presenting ..." I'm surprised that this paragraph is not teasing the fact that one of the contributions is a new way to do prefix acceleration in a PikeVM, something that is not the usual way to perform the optimization
]

#include "/content/introduction.typ"
#include "/content/background/background.typ"
#include "/content/chapters/chapters.typ"
#include "/content/evaluation.typ"
#include "/content/discussion.typ"
