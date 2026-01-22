#import "/prelude.typ": *

#set text(font: fonts.sans)

Modern regular expressions (regexes) are a powerful tool for finding patterns in text. Modern features such as capturing groups, lookarounds, and backreferences turn the problem of matching into a complex and error-prone task. Real-world implementations additionally employ a large variety of optimizations and heuristics to speed up matching in practice. In this work we don't shy away from this complexity but instead tame it by providing a formalization of realistic regex matching that includes all of the cumbersome aspects. In the Rocq proof assistant, we provide the first formalization and proof of correctness of a prefix acceleration optimization in the PikeVM. We additionally formalize optimizations such as anchored regexes and impossible matches. We combine all of them to produce a realistic matching algorithm which is proven to return matches defined by the ECMAScript 2023 standard.
