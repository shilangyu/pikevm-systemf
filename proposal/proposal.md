# Extending the PikeVM formalization of ECMAScript regexes

## Abstract

The ECMAScript specification of
[regular expressions](https://262.ecma-international.org/16.0/#sec-regexp-regular-expression-objects)
found in the JavaScript language grows in complexity over time. To improve our
confidence in the correctness of regex engines following the specification, we
reach for the computer scientist's most loved and feared tool: mechanization of
its semantics. Building upon prior work, the goal of the project is to extend
the PikeVM formalization to support a larger set of features of regular
expressions and to prove the correctness of some optimizations. Namely, add the
support of look-arounds, prove correctness of prefix acceleration, and prove the
optimization of bounded look-arounds.

## Introduction

The previously completed mechanization of the ECMAScript regexes, called
[Warblre](https://dl.acm.org/doi/10.1145/3674666), is complete and faithful to
the specification. Consequently, a second formalization, called
[Linden](https://arxiv.org/abs/2507.13091), was completed and proven to be
equivalent to Warblre. While Warblre stays faithful to the official
specification, its style of semantics is not convenient for doing proofs. Linden
improves on that by introducing backtracking trees defined by an inductive
relation. Linden goes a step further, by also including a verified engine.

As such, the equivalent and simpler representation can be used to prove more
properties in an easier fashion. The PikeVM algorithm is a popular linear-time
matching algorithm that supports a subset of the modern regex features. In
Linden, the mechanization of the PikeVM algorithm was created and proven
correct. However, it is missing some of the regex features which we know we can
match in linear-time, such as
[look-arounds](https://aurele-barriere.github.io/papers/linearjs.pdf).

Modern regex engines are full of heuristics which preserve the semantics of
matching, but speed it up greatly in practice. Given a mechanization, we can
confidently prove the correctness of these optimizations/heuristics.

## Proposal

The overarching goal of the project is making the verified PikeVM more
expressive and efficient. To that end, what follows are outlines of milestones
that bring us closer to that goal.

As a warm-up exercise, zero-length assertions (ie. `$`, `\b`, `^`, etc) will be
added to the PikeVM and proven correct. This will give a good understanding of
the existing Rocq codebase while contributing something useful.

Then, a large chunk of the effort will be focused on extending the PikeVM
mechanization to support look-arounds. This will be split into two categories,
those look-arounds which can be implemented with a streaming algorithm
(captureless look-behinds), and those for which we don't have a streaming
implementation for.

Additionally, the aim is to prove correctness of an important optimization used
by many real-world regex engines called prefix acceleration. This optimization
works whenever we know that a regex's match will always be prefixed by some
fixed literal. In that case a much faster classical substring search can be
employed to find this literal in the haystack and run the PikeVM only at these
points.

Finally, if time allows the following extensions will be explored:

- Prove correctness of the bounded look-behind optimization (explained
  [here](https://systemf.epfl.ch/blog/rust-regex-lookbehinds/#bounded-lookbehinds-optimization-marcin))
- Implement prefix acceleration in the
  [LinearV8 engine](https://v8.dev/blog/non-backtracking-regexp)
- Add the `+` quantifier to the PikeVM mechanization

As with any formalization effort, the main obstacles are all of the unexpected
difficulties that will be encountered when trying to prove even seemingly
trivial properties. Patience and focus will be the two great virtues fully
embodied throughout this project.

## Timeline

| Week    | Task                                                                      |
| ------- | ------------------------------------------------------------------------- |
| 1       | Background reading, tools setup, proposal and presentation preparation    |
| 2       | Formalizing zero-length assertions in the PikeVM                          |
| 3 - 9   | Formalization of the non-streaming implementation of look-arounds         |
| 10 - 13 | Formalization of the prefix acceleration                                  |
| 14 - 16 | Formalization of the streaming implementation of captureless look-behinds |
| 17 - 18 | Writing the report                                                        |
