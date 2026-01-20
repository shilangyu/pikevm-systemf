#import "/prelude.typ": *

= Meta engine <sec:meta-engine>

Individual regex engines have their strength and weaknesses. Some operate better when specific regex features are used, others excel whenever the haystack is small. Some suffer from having a troublesome space complexity, others don't support all of the desired regex features. To get the best of all worlds, modern regex libraries implement so-called _meta engines_ which combine multiple individual engines and select the best one for a given regex and haystack. The goal of the Meta engine is to take high-level decisions such as selecting the best engine for the job guided by heuristics and perform engine-independent optimizations. At times, we may even want to skip running any engine at all or combine multiple in the same matching process.

As mentioned in @sec:pikevm, PikeVM remains as the most feature-complete engine with a linear runtime complexity and a reasonable space complexity. Its importance is undeniable. But as noted by the author of the Rust `regex` @crate:intro @rust-regex,

#show quote: emph

#quote(attribution: [Andrew Gallant @rust-regex-blog], block: true)[
  ... the less time we can spend in specifically the PikeVM, the better.
]

This harsh statement stems from the fact that while the PikeVM has favorable properties, it tends to be rather slow in practice. We know many other regex matching algorithms which are considerably faster in practice. Their speed is partially attributed to them being specialized for specific regex features or haystack characteristics. In Linden, besides the PikeVM, another engine called the @memo-bt:intro has been mechanized and verified. In benchmarks the MemoBT tends to be roughly 2$times$ faster than the PikeVM @rebar. However, its drawback is that its space complexity is expressed in terms of both the regex and haystack size, $O(|r| dot |s|)$ (as opposed to PikeVM's $O(|r|)$), making it impractical for large haystacks. Tools like UNIX's `grep` commandline tool which given a regex finds matches in files, often perform searches on rather large files, and so the incurred memory cost of the MemoBT is at times prohibitive.

In this chapter we formalize such a Meta engine and prove the correctness of its decision procedures and various optimizations it performs. Since at the moment of writing only the PikeVM and the MemoBT engines have been mechanized in Linden, we focus on those. We start by formalizing what it means to be an engine in @sec:engine-interface. Next, we revisit literal extraction to leverage ```rocq Exact``` and ```rocq Impossible``` literals in @sec:literal-optimizations. Then, we take advantage of anchors in regexes to avoid redundant work in @sec:anchored-optimization. Finally, we combine everything together into a single Meta engine in @sec:meta-search.


#include "engine.typ"
#include "literals.typ"
#include "anchored.typ"
#include "meta_search.typ"
