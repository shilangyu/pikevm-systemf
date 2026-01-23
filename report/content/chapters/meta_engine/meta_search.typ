#import "/prelude.typ": *

== Meta search <sec:meta-search>

With all of the theory of engines, the correctness proofs of optimizations, the formalization of literals and substring searches, we can finally put everything together into a single unified regex engine which will leverage all of the mentioned components with the intention of being as efficient as possible. This Meta engine will be split into two. A smaller anchored meta engine which is only focused on picking the best engine for the job. Then, a larger unanchored Meta engine will take advantage of all of the components laid out in the previous chapters and sections.

To guide heuristics, we define a configuration type which holds parameters which influence the decisions made by the Meta engine. For now, we only store the memory limit we wish to impose on the engines during runtime. If an engine can potentially go over that limit, it will not be considered for execution. If no memory limit is provided, it is assumed that there is no limit on the memory usage. We express this limit with a natural number $n$ and interpret it as an abstract memory usage unit. It serves as a configuration knob where a larger number allows for a bigger memory usage. We additionally define the estimated peak usage of the MemoBT as $|r| dot |s|$ for a regex $r$ and a haystack $s$.

#linden-listing("Engine/Meta/Meta.v", (
  "meta_config",
  "memobt_peak_memory_usage",
))[The definition of the Meta engine configuration and the estimate of MemoBT's memory usage.]

The anchored Meta engine is simple and its definition can be found in @lst:meta-anchored-engine. It first checks if the provided memory limit allows for running the MemoBT engine. If yes, we run it. Otherwise, we fall back to the PikeVM. To run an engine we use its ```rocq exec``` function provided by the ```rocq AnchoredEngine``` typeclass instance. Running them requires providing additional instances, for instance for the substring search, the PikeVM's seen set implementation, or MemoBT's memoization implementation.

#linden-listing(
  "Engine/Meta/Meta.v",
  "meta_search_anchored",
)[Definition of the anchored Meta search function.] <lst:meta-anchored-engine>

The correctness follows directly from the correctness of the individual engines. The heuristic of picking an engine does not affect correctness; regardless which engine was picked, the engine will produce a correct result. Heuristics affect only the practical aspect of performing matching. We state this correctness theorem in @thm:meta-anchored-correctness. For any configuration, supported regex, and haystack, running the anchored Meta engine produces the same result as defined by the formal semantics of backtracking trees. ```rocq meta_supported_regex``` accepts exactly the same regexes as the PikeVM and the MemoBT. Thus, this Meta anchored matching function is another instance of the ```rocq AnchoredEngine``` typeclass#note[Proven in #linden-permalink(linden-statement("Engine/Meta/Meta.v", "MetaSearchAnchored")).].

#linden-theorem("Engine/Meta/Meta.v", "meta_search_anchored_correct") <thm:meta-anchored-correctness>

We are now ready to define the final, neat, all-encompassing unanchored Meta engine given by ```rocq search``` seen in @lst:meta-unanchored-engine.

#linden-listing(
  "Engine/Meta/Meta.v",
  "search",
)[Definition of the unanchored Meta search function.] <lst:meta-unanchored-engine>

This function first tries to dispatch matching methods that do not require running a full regex engine. As such, it first attempts to find the match using literal optimizations from @lst:try-lit-search. For lack of a better instance at the moment of writing, we use the naive brute-force substring search algorithm defined in @lst:naive-substring-search. If this attempt is unable to find a match, we reach for the anchored search optimization from @lst:try-anchored-search. The anchored engine used here is the anchored Meta engine defined in @lst:meta-anchored-engine. If this also does not yield a match, we try the last trick before having to succumb to using a full unanchored engines. We perform prefix acceleration once using the definition from @lst:search-acc-once. To decide on the underlying engine, we again use the provided memory limit configuration. If the memory limit allows for running the MemoBT engine, we do so by means of the unanchoring technique from @lst:unanchor-engine. This means we run the anchored MemoBT with the lazy prefix prepended to the regex. For the MemoBT we must additionally provide a proof that it indeed supports regexes with the lazy prefix. If the memory limit could potentially be exceeded, we use the prefix-accelerated unanchored PikeVM from @sec:unanchored-pikevm. We conclude with proving the correctness of this unanchored Meta engine in @thm:meta-unanchored-correctness. For any configuration, supported regex, and haystack, running the unanchored Meta engine produces the same result as defined by the formal semantics of backtracking trees for a regex with the lazy prefix. This, of course, is another instance of an ```rocq UnanchoredEngine```#note[Proven in #linden-permalink(linden-statement("Engine/Meta/Meta.v", "MetaEngine")).].

#linden-theorem("Engine/Meta/Meta.v", "search_correct", proof: [
  By @thm:try-lit-search-correctness, @thm:try-anchored-search-correctness, @thm:search-acc-once-correctness, and the correctness of the individual engines and the unanchoring construction.
]) <thm:meta-unanchored-correctness>
