#import "/prelude.typ": *

== Correctness of literal extraction <sec:literal-extraction-correctness>

We now prove that the extracted literals gives us some useful information about the matches of a regex. The properties which we care about are those which allow us to accelerate regex matching. For that, we consider three useful properties separately. For any literal whose prefix (@lst:prefix) is `s`, we show that any match of a regex $r$ must start with the string $s$. Through the contrapositive (if a match does not start with $s$, it is not a match of $r$) we are able to do prefix acceleration by skipping haystack positions where $s$ does no occur. For ```rocq Impossible``` literals, we show that no match of $r$ whose literal is ```rocq Impossible``` can exist. This allows us to immediately say that for such a regex and any haystack, there is no match. Finally, for ```rocq Exact s``` literals, we show that any match of a regex $r$ whose literal is ```rocq Exact s``` is exactly the string $s$. This allows us to skip running regex engines entirely and just use a much faster substring search.

#linden-listing("Engine/Prefix.v", (
  "extract_action_literal",
  "extract_actions_literal",
))[Definitions of literal extractions generalized to tree actions.] <lst:extract-literal-actions>

We want the theorems to be stated in terms of the ```rocq is_tree``` inductive#note[See @sec:backtracking-trees], preferably talking about a specific regex, ie. ```rocq is_tree [Areg r]```. Recall, however, that some of its rules such as the ```rocq tree_sequence``` rule talk about more than just the head of the tree actions. That means that in the proofs during induction over ```rocq is_tree``` we must generalize  over the entire list of tree actions, otherwise we will get stuck on those rules. To avoid this, we generalize literal extraction over an action and a list of actions in @lst:extract-literal-actions and state the theorems in terms of these.

For ```rocq extract_action_literal``` we return ```rocq Nothing``` for non-regex actions, since they do not consume any characters from the input. For ```rocq extract_actions_literal```, we chain the literals of each action. When the list of actions is empty, we return the same literal as we would for $epsilon$, ```rocq Nothing```. The choice of chaining becomes apparent when we look again at the ```rocq tree_sequence``` rule: ```rocq is_tree (Areg (Sequence r1 r2) :: cont)``` holds if ```rocq is_tree (Areg r1 :: Areg r2 :: cont)```#note[This is when the direction is `forward`. When the direction is `backward`, the condition is ```rocq is_tree (Areg r2 :: Areg r1 :: cont)```, leading to the same illustration of the argument.] does.

With those definitions in place, we can now state the correctness theorems for each literal variant.

=== Correctness of the prefix of literals

We first want to state the correctness lemma of ```rocq extract_literal_char```. We want to say that given a character descriptor `cd` and a character `c` that matches it, the extracted literal from `cd` is the prefix of `c`. This is formalized by @thm:correctness-extract-literal-char. In that statement we additionally generalize over the tail of the string where `c` is the head of it. Since the `ignoreCase` flag was not checked in ```rocq extract_literal_char```, we additionally add it to our hypotheses.

#linden-theorem("Engine/Prefix.v", "chain_literals_extract_char", proof: [
  We induct on `cd` yielding cases for each character descriptor. Each case is closed directly or by cases analysis of `rest` and by the induction hypotheses.
]) <thm:correctness-extract-literal-char>

With that lemma we can now state and prove the general lemma about the correctness of the prefix of extracted literals for regexes. Given a tree `tree` of actions `acts` over the input `inp`, if `tree` contains a match then `inp` starts with the prefix of the literal extracted from `acts`.

#linden-theorem("Engine/Prefix.v", "extract_literal_prefix_general", proof: [
  We induct on the ```rocq is_tree``` hypothesis and use @thm:correctness-extract-literal-char.
]) <thm:correctness-extract-literal-prefix-general>

Given the generalized lemma we can now specialize it to the case where the list of actions is exactly just the regex `r` itself. This gives us @thm:correctness-extract-literal-prefix.

#linden-theorem("Engine/Prefix.v", "extract_literal_prefix", proof: [
  This holds directly from @thm:correctness-extract-literal-prefix-general with `acts = [Areg r]`.
]) <thm:correctness-extract-literal-prefix>

In practice, however, this theorem will be of little direct use. We wish to instead have a theorem which would talk about the matches of a tree given some information about whether the input starts with the prefix of the literal. What we precisely want is the contrapositive of @thm:correctness-extract-literal-prefix which is stated in @thm:correctness-extract-literal-prefix-contra.

#linden-theorem("Engine/Prefix.v", "extract_literal_prefix_contra") <thm:correctness-extract-literal-prefix-contra>

=== Correctness of ```rocq Impossible``` literals

Similarly we must first state the correctness lemma of ```rocq extract_literal_char``` for when it returns ```rocq Impossible```. Given a character descriptor `cd` for which we extract the literal ```rocq Impossible```, no character `c` can be matched with `cd`. This is formalized by @thm:correctness-extract-literal-char-impossible.

#linden-theorem("Engine/Prefix.v", "extract_literal_char_impossible_no_match", proof: [
  By induction on `cd`.
]) <thm:correctness-extract-literal-char-impossible>

With that lemma we prove the general lemma about the ```rocq Impossible```. Given a tree `tree` of actions `acts` over the input `inp`, if the literal extracted from `acts` is ```rocq Impossible```, then no match can exist in `tree`.

#pagebreak(weak: true)

#linden-theorem("Engine/Prefix.v", "extract_literal_impossible_general", proof: [
  We induct on the ```rocq is_tree``` hypothesis and use @thm:correctness-extract-literal-char-impossible.
]) <thm:correctness-extract-literal-impossible-general>

And finally, we specialize it to the case where the list of actions is exactly just the regex `r` itself. This gives us @thm:correctness-extract-literal-impossible.

#linden-theorem("Engine/Prefix.v", "extract_literal_impossible", proof: [
  This holds directly from @thm:correctness-extract-literal-impossible-general with `acts = [Areg r]`.
]) <thm:correctness-extract-literal-impossible>

=== Correctness of ```rocq Exact``` literals

For exact literals, we want to argue that the first occurrence of the literal in the haystack corresponds to the match of the regex. We must first notice, however, that if a regex has any assertions, we cannot leverage ```rocq Exact``` literals because typically substring search algorithms do not support assertions. An assertion is a regex construct which does not consume any characters during matching but instead inspects the surrounding context of the match. Anchors and lookarounds precisely constitute assertions. We define ```rocq has_asserts``` in @lst:has-asserts. Consider the regex ```re /\babc/``` for which we extract the literal ```rocq Exact "abc"```. This is what we want; a match of this regex will always be exactly the string #hay[abc]. However, due to the word boundary assertion (```re \b```) at the start, we cannot simply search for #hay[abc] in the haystack. We must also ensure that at the position where #hay[abc] is found, a word boundary exists.

#linden-listing(
  "Engine/Prefix.v",
  "has_asserts",
)[Function checking whether a regex contains assertions.] <lst:has-asserts>

We first prove that exact character descriptors always match the extracted character, as seen in @thm:extract-literal-char-exact-char-match.

#linden-theorem("Engine/Prefix.v", "extract_literal_char_exact_char_match", proof: [
  Induction on `cd`.
]) <thm:extract-literal-char-exact-char-match>

With that we prove that if the haystack starts with the exact literal, then the end of that match is at our position advanced by the length of the literal. This is formalized in @thm:exact-literal-result. Since we know nothing about the resulting group map, we existentially quantify it.

#linden-theorem("Engine/Prefix.v", "exact_literal_result", proof: [
  Induction on `is_tree`.
]) <thm:exact-literal-result>

This theorem is not yet useful, as it only states the result for anchored searches. We therefore must additionally prove a similar result for unanchored searches seen in @thm:exact-literal-result-unanchored. If we have no asserts, an exact literal, a position of the literal found by substring search, then the result of the unanchored search is precisely that position found by the substring search advanced by the length of the literal. Again, we know nothing about the group map.

#linden-theorem("Engine/Prefix.v", "exact_literal_result_unanchored", proof: [
  Induction on `inp`.
]) <thm:exact-literal-result-unanchored>
