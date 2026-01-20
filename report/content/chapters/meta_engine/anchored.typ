#import "/prelude.typ": *

== Anchored optimization <sec:anchored-optimization>

Besides using regexes to search through large amounts of text, another common use-case is to use them to validate the format of user inputs such as form fields, passwords, or simple syntaxes. In such scenarios, the regex is expected to describe the input in its entirety. For example, the regex ```re /^\d{4}-\d{2}-\d{2}$/``` which validates date strings in the format of "YYYY-MM-DD" is _anchored_ from both ends with the ```re ^``` and ```re $``` symbols. They respectively require the matching to start at the beginning of the haystack and end at the end of the haystack. Lack of these anchors would allow the regex to match arbitrarily in the haystack which is not be desirable for input validation. Regexes which require a ```re ^``` for matching are called _anchored_ regexes. This is related to the notion of anchored matching as both can only match at the current haystack position. In addition, anchored regexes cannot be made unanchored by the addition of a @lazy-prefix: ```re /[^]*?^r/``` will fail to match at any haystack position other than the very first one. Thus, for any anchored regex $r$, the result of performing anchored matching is the same as the result of performing unanchored matching.

This exact observation allows us to implement an optimization for anchored regexes. If the regex is anchored, we only attempt to match at the beginning of the haystack, regardless of whether we are performing anchored or unanchored matching. On top of that, we can perform this optimization by just using anchored engines. We start our formalization by defining the simple static analysis which determines whether a regex is anchored or not, seen in @lst:is-anchored.

#linden-listing("Engine/Meta/MetaAnchored.v", (
  "is_anchored'",
  "is_anchored",
))[Definition of anchored regexes.] <lst:is-anchored>

For a regex to be anchored, it does not necessarily need to start with the ```re ^``` anchor. It suffices that the ```re ^``` anchor is *required* to be fulfilled for any successful match. This means that in our analysis for the case of a sequence, if either side is anchored, the entire sequence is anchored. On the other hand, for a disjunction both branches must be anchored. Consider ```re /^a|b/```, the first branch is indeed anchored, but the second branch could potentially match at any haystack position, so we cannot deem that regex anchored. A quantifier is anchored only if its body is anchored and the quantifier has a minimal iteration count greater than zero. This is to ensure that regexes like ```re /(^a)*b/``` are not considered anchored since ```re *``` allows for the body to be matched zero times. The last interesting case is that of lookarounds. A positive lookahead is indeed anchored if its body is anchored, but that does not hold true for positive lookbehinds! Consider ```re /(?<=^a+)b/```. The inside of the lookbehind is anchored, but the entire regex fails to match at #hay(position: 0)[ab] yet succeeds at #hay(position: 1)[ab], meaning the regex is not anchored. Negative lookarounds do not contribute to anchoring since they only assert the non-existence of a match. Lastly, we must guard the entire analysis on the `multiline` flag (see @sec:flags). When the flag is enabled, the anchor ```re ^``` is allowed to additionally match the beginning of lines, not just the beginning of the haystack. This means that regexes like ```re /^a/m``` could match at multiple haystack positions, so we cannot consider them anchored.

We now define the anchored optimization in @lst:try-anchored-search. Given a regex, a haystack, and an anchored engine, if possible we return the result of *unanchored* matching. The return type is a doubly nested option for the same reason as in @sec:exact-impossible-literals. Other than checking if the regex is anchored, we additionally check if the passed haystack is set to the beginning position. If it is, we return the result obtained from running the anchored engine. If it is not at the beginning position, we immediately know matching would fail and thus return ```rocq Some None```.

#linden-listing(
  "Engine/Meta/MetaAnchored.v",
  "try_anchored_search",
)[Anchored search optimization definition.] <lst:try-anchored-search>

==== Correctness
As per usual, we first need auxiliary definitions which generalize anchor detection to tree actions.

#linden-listing(
  "Engine/Meta/MetaAnchored.v",
  ("is_anchored_act", "is_anchored_acts"),
)[Definitions checking whether an action and a list of actions is anchored.] <lst:is-anchored-actions>

Then, we say that given an anchored list of actions and a haystack at a position different then the beginning, no match can exist. This is formalized in @thm:anchored-match-not-begin. Recall that in Linden, inputs (which represent haystacks along with the current positions) are formed from a string of future characters and a string of past characters. So to say that a haystack is set to a positions different than the beginning, it is the same as saying the string of past characters is non-empty. We represent it here by explicitly forming the Linden input type with the past characters being constructed by the List's ```rocq cons``` (```rocq ::```) constructor which is by definition non-empty.

#linden-theorem("Engine/Meta/MetaAnchored.v", "is_anchored_match_not_begin", proof: [
  By induction over ```rocq is_tree```.
]) <thm:anchored-match-not-begin>

We specialize the lemma to the case of regexes.

#linden-theorem("Engine/Meta/MetaAnchored.v", "is_anchored_match_not_begin_regex", proof: [
  This holds directly from @thm:anchored-match-not-begin with `acts = [Areg r]`.
]) <thm:anchored-regex-match-not-begin>

And we conclude with the correctness theorem of ```rocq try_anchored_search``` in @thm:try-anchored-search-correctness. If ```rocq try_anchored_search``` returns ```rocq Some```, then the contained result corresponds exactly to the result defined by the backtracking tree semantics of the regex with a lazy prefix. We are not interested in the case where ```rocq try_anchored_search``` returns ```rocq None``` as that indicates that no optimization was possible.

#linden-theorem("Engine/Meta/MetaAnchored.v", "try_anchored_search_correct", proof: [
  By the correctness of the anchored engine and by @thm:anchored-regex-match-not-begin.
]) <thm:try-anchored-search-correctness>
