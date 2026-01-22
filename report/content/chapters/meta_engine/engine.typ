#import "/prelude.typ": *

== Engine interface <sec:engine-interface>

So far we have been mentioning regex @engine:plural in a rather informal manner. In this section we formalize this notion. Some optimizations which we perform in the following sections hold true for any engine even when treated as a black-box. Hence having an abstract description of what an engine is allows us to state more general results. Since anchored and unanchored engines return fundamentally different results of matching, we separate them into two disjoint definitions.

The typeclass describing an anchored regex engine given in @lst:anchored-engine-class contains three members. First, it must contain a function which will perform the actual matching, ```rocq exec```. Given a regex and a haystack, it optionally returns a result. To control which regexes the engine supports, it must additionally provide a predicate ```supported_regex``` which given a regex returns whether the engine is able to execute it. Finally, there is a single correctness axiom the engine must fulfill, ```rocq exec_correct```. It states that that for any #underline[supported] regex $r$ and any haystack $s$, the engine (```rocq exec r s```) returns exactly the same result as the one defined by the semantics of backtracking trees. This in turn means that the engine finds a match as defined by the ECMAScript standard.

#linden-listing(
  "Engine/Meta/EngineSpec.v",
  "AnchoredEngine",
)[Typeclass describing an anchored engine] <lst:anchored-engine-class>


To describe unanchored engines, we first define the @lazy-prefix:intro as simply being the sequencing of ```re /[^]*?/``` with a regex `r`. Then, the typeclass definition of an unanchored engine seen in @lst:unanchored-engine-class is very similar to that of an anchored engine. The sole difference is that for the correctness axiom, we require that the engine, when given a regex `r` and a haystack `s`, returns the same result as the one defined by the semantics of a backtracking tree for ```re /[^]*?r/```! All typeclass member names are prefixed with `un_`.

#linden-listing(
  "Engine/Meta/EngineSpec.v",
  ("dot_star", "lazy_prefix", "UnanchoredEngine"),
)[The definition of the lazy prefix and the typeclass describing an unanchored engine] <lst:unanchored-engine-class>

Given those definitions we can now exhibit some instances of those typeclasses. Naturally, the anchored PikeVM defined in @sec:pikevm is an instance of the anchored engine typeclass#note[Proven in #source-permalink(find-statement("Engine/Meta/EngineSpec.v", "PikeVMAnchoredEngine"))]. Its proof of ```rocq exec``` correctness is derived from proofs previously present in Linden. We also show that the unanchored PikeVM defined in @sec:unanchored-pikevm is an instance of the unanchored engine typeclass#note[Proven in #source-permalink(find-statement("Engine/Meta/EngineSpec.v", "PikeVMUnanchoredEngine"))]. Its proof of ```rocq un_exec``` correctness is derived from proofs discussed in @sec:unanchored-pikevm-correctness. For both PikeVMs, the ```rocq supported_regex```#note[The PikeVM regex support predicate can be found in #source-permalink(find-statement("Engine/PikeSubset.v", "is_pike_regex"))] predicate notably excludes regexes with backreferences (due to not having a linear-time implementation) and with lookarounds (which have yet to be verified in the PikeVM#note[A very recent development @linearjsregex has found a way to incorporate lookarounds into the PikeVM under the ECMAScript semantics. No mechanization of this fact has been yet completed.]). Similarly, the already verified MemoBT engine is an instance of an anchored engine#note[Proven in #source-permalink(find-statement("Engine/Meta/EngineSpec.v", "MemoBTAnchoredEngine"))]. There is currently, however, no verified specialized unanchored version of the MemoBT engine in Linden. Instead, we notice that every anchored engine can be turned into an unanchored one.

As stated in @sec:prefix-acceleration, by running an anchored engine on a regex augmented with the @lazy-prefix:intro, we can perform unanchored matching. We prove this by providing a generic instance ```rocq UnanchorEngine``` (@lst:unanchor-engine) which given any anchored engine produces an unanchored one. We must additionally have a precondition that for any regex supported by the anchored regex, its lazy prefix is also supported. With this assumption, the correctness of ```rocq un_exec``` follows directly from the correctness of ```rocq exec``` of the anchored engine.

#linden-listing(
  "Engine/Meta/EngineSpec.v",
  ("lazy_prefix_supported", "UnanchorEngine"),
)[Turning any anchored engine into an unanchored one.] <lst:unanchor-engine>
