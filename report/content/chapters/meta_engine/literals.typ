#import "/prelude.typ": *

== Literal optimizations <sec:literal-optimizations>

In @sec:prefix-acceleration we have seen how by using the prefix of an extracted literal of a regex we can accelerate matching by skipping parts of the haystack. We did so by deeply integrating this prefix acceleration optimization into the PikeVM engine. However, we have also discussed that under the black-box assumption, which our engine typeclasses describe, a limited but nonetheless useful variant of prefix acceleration can be performed. Additionally, in @sec:literals we have created the theory of both ```rocq Impossible``` and ```rocq Exact``` literals, but have yet to leverage them for optimizations. In this section we correct this by formalizing an optimization performing this limited form of prefix acceleration as well as optimizations utilizing those two literal kinds.

=== One-time prefix acceleration

#TODO[I just realized that the theorem proven in Linden about doing prefix acceleration once proves something that is not really usable and not what I described here. Fix either the theorem or the description here.]

=== ```rocq Exact``` and ```rocq Impossible``` literals <sec:exact-impossible-literals>

To take advantage of the ```rocq Exact``` and ```rocq Impossible``` literals, we define the function ```rocq try_lit_search``` as seen in @lst:try-lit-search.

#linden-listing(
  "Engine/Meta/MetaLiterals.v",
  "try_lit_search",
)[Definition of the function which attempts to use literals to find definitive matches.] <lst:try-lit-search>

Other than taking as arguments the regex and a haystack, it additionally expects to have an instance of a substring search algorithm defined in @sec:substring-search. Notably, no engine is passed as an argument as here we focus on optimizations not requiring them. Its return type is a doubly-nested optional result of matching. The outer option indicates whether this function is able to find the match at all. The inner option indicates whether a match exists. Thus while ```rocq None``` means that the ```rocq try_lit_search``` function could not determine what the value of the match is, ```rocq Some None``` means that the match was determined to not exist. This function starts by extracting the literal of the given regex. If that literal is a ```rocq Prefix```, without an engine we cannot determine the match so we return ```rocq None```. In the case of ```rocq Impossible```, we can immediately return that no match exists, ```rocq Some None```. But if the literal is an ```rocq Exact s```, more cases must be considered.

If the regex additionally has any assertions, we cannot leverage ```rocq Exact``` literals and thus we exit with ```rocq None```. An assertion is a regex construct which does not consume any characters during matching but instead inspects the surrounding context of the match. Anchors and lookarounds precisely constitute assertions. We define ```rocq has_asserts``` in @lst:has-asserts. Consider the regex ```re /\babc/``` for which we extract the literal ```rocq Exact "abc"```. This is what we want; a match of this regex will always be exactly the string #hay[abc]. However, due to the word boundary assertion (```re \b```) at the start, we cannot simply search for #hay[abc] in the haystack. We must also ensure that at the position where #hay[abc] is found, a word boundary exists. Without an engine to check this assertion, we cannot proceed and thus return ```rocq None```. Luckily, this ```rocq Exact``` literal will be leveraged during prefix acceleration which will exactly find the instances of #hay[abc] while verifying the assertions.

#linden-listing(
  "Engine/Prefix.v",
  "has_asserts",
)[Function checking whether a regex contains assertions.] <lst:has-asserts>

Once we know no assertions are present, we can proceed to using the substring search algorithm to find the first occurrence of the string $s$ in the haystack. If no such occurrence exists, we can return with ```rocq Some None```. Otherwise, we have found a position which we know corresponds precisely to the leftmost-greedy match. However, if the regex contained any captures, we would have to additionally enter a "_capture reconstruction_" phase to determine the values of each capture. Capture reconstruction has not been verified in this work, so for now we will exit with ```rocq None``` if any captures are present. To check for captures, we define the function ```rocq has_groups``` in @lst:has-captures.

#linden-listing(
  "Engine/Meta/MetaLiterals.v",
  "has_groups",
)[Function checking whether a regex contains captures.] <lst:has-captures>

Finally, if no captures are present we can return a match consisting of the haystack advanced to the position found by the substring search along with an empty group map assignment.


==== Correctness
Before we state the correctness theorem of ```rocq try_lit_search```, we must prove two intermediate lemmas. First is about the value of group maps under the assumption that no captures are present in the regex. For the same reason as in @sec:literal-extraction-correctness, we need to generalize the result over the list of tree actions. As such, we define ```rocq has_groups_action``` which for the regex action it delegates to ```rocq has_groups``` and for the ```rocq Aclose``` action returns true since it corresponds to a capture being closed. For the last action we return false. We intuitively extend this definition to a list of actions. Both definitions are given in @lst:has-captures-actions.

#linden-listing(
  "Engine/Meta/MetaLiterals.v",
  ("has_groups_action", "has_groups_actions"),
)[Definitions checking whether a list of actions contains captures.] <lst:has-captures-actions>

With that we state the lemma of empty group maps in @thm:empty-group-map. It states that given a backtracking tree `tree` of actions `acts`, if no captures are present in `acts` and `tree` contains a match, this match's group map is empty.

#linden-theorem("Engine/Meta/MetaLiterals.v", "no_groups_empty_gm", proof: [
  Follows from induction over ```rocq is_tree```.
]) <thm:empty-group-map>

The second lemma we need before tackling ```rocq try_lit_search``` concerns itself with what we know about the matching results when the substring search reports no found occurrences. Namely, if no occurrence of the prefix of the literal of a regex is found in the haystack, then no match can exist even when performing unanchored matching. This is formalized in @thm:no-substring-no-match.

#linden-theorem("Engine/Prefix.v", "str_search_none_nores_unanchored", proof: [
  Induction on the position in the haystack. We apply @thm:correctness-extract-literal-prefix-contra together with the ```rocq not_found``` axiom of substring searches#note[Defined in @sec:substring-search] to show at each position that a match cannot exist.
]) <thm:no-substring-no-match>
#TODO[Maybe I should trim the `{strs:StrSearch}` from statements]

Having these, we formulate the correctness theorem of ```rocq try_lit_search``` in @thm:try-lit-search-correctness. If ```rocq try_lit_search``` returns ```rocq Some```, then the contained result corresponds exactly to the result defined by the backtracking tree semantics of the regex with a lazy prefix. We are not interested in the case where ```rocq try_lit_search``` returns ```rocq None``` as that indicates that no optimization was possible.

#linden-theorem("Engine/Meta/MetaLiterals.v", "try_lit_search_correct", proof: [
  If the extracted literal is ```rocq Impossible```, proof follows from @thm:correctness-extract-literal-impossible. If the extracted literal is ```rocq Exact``` and we have no assertions, we split into two cases depending on the result of the substring search.
  + The result is ```rocq None``` -- proof follows from @thm:no-substring-no-match.
  + The result is ```rocq Some``` -- proof follows from @thm:empty-group-map and #TODO[Reference theorem about exact literals].
]) <thm:try-lit-search-correctness>
