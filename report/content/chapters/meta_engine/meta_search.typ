#import "/prelude.typ": *

== Meta search <sec:meta-search>

With all of the theory of engines, the correctness proofs of optimizations, the formalization of literals and substring searches, we can finally put everything together into a single unified regex engine which will leverage all of the mentioned components with the intention of being as efficient as possible. This Meta engine will be split into two. A smaller anchored meta engine which is only focused on picking the best engine for the job. Then, a larger unanchored Meta engine will take advantage of all of the components laid out in the previous chapters and sections.

To guide heuristics, we define a configuration type which holds parameters which influence the decisions made by the Meta engine. For now, we only store the memory limit we wish to impose on the engines during runtime. If an engine can potentially go over that limit, it will not be considered for execution. If no memory limit is provided, it is assumed that there is no limit on the memory usage. We express this limit with a natural number $n$ and interpret it as an abstract memory usage unit. It serves as a configuration knob where a larger number allows for a bigger memory usage. We additionally define the estimated peak usage of the MemoBT as $|r| dot |s|$ for a regex $r$ and a haystack $s$.

#linden-listing("Engine/Meta/Meta.v", (
  "meta_config",
  "memobt_peak_memory_usage",
  "can_use_memobt",
))[The definition of the Meta engine configuration and the estimate of MemoBT's memory usage.]

The anchored Meta engine is simple and chosen by the definition in @lst:meta-anchored-pick. It first checks if the provided memory limit allows for running the MemoBT engine. If yes, return it. Otherwise, we fall back to the PikeVM. We provide the instances required for memoization during execution.

#linden-listing(
  "Engine/Meta/Meta.v",
  "pick_meta_anchored",
)[Definition of the picking function for an anchored engine.] <lst:meta-anchored-pick>

We similarly define the picking function for the unanchored Meta engine in @lst:meta-unanchored-pick. We perform prefix acceleration once using the definition from @lst:search-acc-once. To decide on the underlying engine, we again use the provided memory limit configuration. If the memory limit allows for running the MemoBT engine, we do so by means of the unanchoring technique from @lst:unanchor-engine. This means we run the anchored MemoBT with the @lazy-prefix prepended to the regex. For the MemoBT we must additionally provide a proof that it indeed supports regexes with the lazy prefix. If the memory limit could potentially be exceeded, we use the prefix-accelerated unanchored PikeVM from @sec:unanchored-pikevm.

#linden-listing(
  "Engine/Meta/Meta.v",
  "pick_meta_unanchored",
)[Definition of the picking function for an unanchored engine.] <lst:meta-unanchored-pick>

For lack of a better instance at the moment of writing, we use the naive brute-force substring search algorithm defined in @lst:naive-substring-search for all substring searches.

The chosen heuristic (```rocq can_use_memobt```) does not affect the correctness of the Meta engine, so we define the final, neat, all-encompassing unanchored Meta engine abstracted on the chosen heuristic. The heuristic is configured by providing pick functions (for both anchored and unanchored) and proving the returned engines support the regexes we want to match.

#linden-listing(
  "Engine/Meta/Meta.v",
  ("meta_heuristic", "meta_search"),
)[Definition of the picking function for an unanchored engine.] <lst:meta-search>

The ```rocq meta_search``` function in @lst:meta-search first tries to dispatch matching methods that do not require running a full regex engine. As such, it first attempts to find the match using literal optimizations from @lst:try-lit-search. If this attempt is unable to find a match, we reach for the anchored search optimization from @lst:try-anchored-search. If this also does not yield a match, we have to succumb to using a full unanchored engines.

The correctness follows directly from the correctness of the individual engines. The heuristic of picking an engine does not affect correctness; regardless which engine was picked, the engine will produce a correct result. Heuristics affect only the practical aspect of performing matching. We state this correctness theorem in @thm:meta-search-correct. For any heuristic, supported regex, and haystack, running the Meta engine produces the same result as defined by the formal semantics of backtracking trees.

#linden-theorem("Engine/Meta/Meta.v", "meta_search_correct") <thm:meta-search-correct>

We conclude with producing a concrete instance of the heuristic in @lst:search and showing that it itself is an unanchored engine.

#linden-listing(
  "Engine/Meta/Meta.v",
  ("search", "MetaEngine"),
)[Definition of the unanchored Meta search function.] <lst:search>
