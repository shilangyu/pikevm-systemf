# Extending the PikeVM formalization of ECMAScript regexes

## Abstract

Building upon prior work, the goal of the project is to extend the PikeVM Rocq
formalization to support a larger set of features of regular expressions and to
prove the correctness of some optimizations. Namely, add the support of
look-arounds and anchors, prove correctness of prefix acceleration, and prove
the optimization of bounded look-arounds.

## Intruction

Classical regular expressions (regexes) have been studied for decades and
believed to be well understood. However, modern regexes used in programming
languages support additional features making the matching problem more
complicated. Combined with the need for real-world modern regex engines to be
fast, it leads to buggy implementations. Their optimized algorithms containing
many heuristics go beyond what has been done in the state-of-the-art verified
matching.

One such engine on which this project will be focused on is the PikeVM. It
supports a subset of modern regex features while maintaining a matching runtime
linear with respect to the regex and input size. In prior work on
[Linden](https://arxiv.org/abs/2507.13091), the PikeVM algorithm was formalized
in Rocq and proven correct. However, the current formalization is missing
heuristics used in real-world implementations. This project will extend that
formalization to prove correctness of some optimizations and heuristics used in
real-world PikeVM implementations.

The regex semantics used in this project are those that follow the
[ECMAScript 2023 specification of regular expressions](https://tc39.es/ecma262/2023/#sec-compilepattern).
[Recent work](https://dl.acm.org/doi/10.1145/3656431) has shown that these
semantics exhibit favorable properties allowing unbounded look-arounds to be
matched in linear time by the PikeVM. The current mechanization is missing this
and some other regex features for which we know we can implement in the PikeVM.
This project will additionally extend the formalization to support a larger
subset of regex.

## Proposal

The overarching goal of the project is making the verified PikeVM more
expressive and efficient. To that end, what follows are outlines of milestones
that bring us closer to that goal.

As a warm-up exercise, zero-length assertions (`^`, `$`, `\b`, `\B`) will be
added to the PikeVM and proven correct. This will give a good understanding of
the existing Rocq codebase while contributing something useful.

Once warmed up, the aim is to prove correctness of an important optimization
used by many real-world regex engines called prefix acceleration. This
optimization works whenever we know that a regex's match will always be prefixed
by some fixed literal. In that case a much faster classical substring search can
be employed to find this literal in the haystack and run the PikeVM only at
these points.

Then, a large chunk of the effort will be focused on extending the PikeVM
mechanization to support look-arounds. This will be split into two categories,
those look-arounds which can be implemented with a streaming algorithm
(captureless look-behinds), and those for which we don't have a streaming
implementation for.

Finally, if time allows the following extensions will be explored:

- Prove correctness of the bounded look-behind optimization (explained
  [here](https://systemf.epfl.ch/blog/rust-regex-lookbehinds/#bounded-lookbehinds-optimization-marcin))
- Implement prefix acceleration in the
  [LinearV8 engine](https://v8.dev/blog/non-backtracking-regexp)
- Either,
  - add the `?` and `??` quantifiers to the PikeVM mechanization **and** prove
    equivalence between general quantifiers and a regex AST rewrite + usage of
    `*`/`*?`/`?`/`??`, _or_
  - add general quantifiers to the PikeVM

## Timeline

| Week    | Task                                                                                                                      |
| ------- | ------------------------------------------------------------------------------------------------------------------------- |
| 1       | Background reading, tools setup, proposal and presentation preparation. Formalizing zero-length assertions in the PikeVM. |
| 2 - 5   | Formalization of the prefix acceleration                                                                                  |
| 5 - 11  | Formalization of the non-streaming implementation of look-arounds                                                         |
| 12 - 15 | Formalization of the streaming implementation of captureless look-behinds                                                 |
| 16 - 18 | Writing the report. Exploring extensions                                                                                  |

## Related work

- https://dl.acm.org/doi/10.1145/3656431 -- linear matching of look-arounds in
  the PikeVM
- [Warblre](https://dl.acm.org/doi/10.1145/3674666) -- mechanization of
  ECMAScript 2023 regexes. Linden semantics are proven to be equivalent to those
  of Warblre.
- [Linden](https://arxiv.org/abs/2507.13091) -- mechanization of backtracking
  tree semantics and the PikeVM algorithm.
- https://dl.acm.org/doi/10.1145/3703595.3705884 -- verified matching of regular
  expressions with look-arounds. Linearity only shown experimentally
- https://dl.acm.org/doi/10.1145/3636501.3636959 - verified matching of
  derivative-based regular expressions with look-arounds
