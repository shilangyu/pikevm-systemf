#import "/prelude.typ": *

= Literal extraction <sec:literal-extraction>

#let ex = ```regex abc\d+```
#let ex-unanch = ```regex .*abc\d+```
#let ex-hay = hay("abc")

One characteristic of regexes which is often exploited for optimization in practice is the knowledge that certain parts of the regex matches literals. Take for example the regex #ex. We can see that any match this regex can produce must contain the constant string #ex-hay. So if a haystack does not contain #ex-hay, we can immediately conclude no match can be found. To speed up looking for matches one can also just look for matches in the neighborhoods of occurrences of #ex-hay in the haystack. Unfortunately, "_searching in the neighborhoods_" is too general of a notion to be useful in practice. Consider ```regex .*abc\d+```. We still know that any match must contain #ex-hay, but what is the neighborhood of #ex-hay in this case? Because of the ```regex .*``` preceding the #ex-hay, *everything* before #ex-hay can potentially be part of the match. This means we lost any benefit gained from knowing that there is this constant string there.

Let's go back to the original example of #ex. A more precise information which we can extract here is that not only does any match has to contain #ex-hay, any match *must start* with #ex-hay. This stronger property can be used more directly: first we look for occurrences of #ex-hay and at this position exactly we try to match the regex. If we fail, we can simply move on to the next occurrence. This optimization is commonly referred to as the "prefix acceleration" and is deployed in many real-world regex engines. Informed by the #TODO[frequency at which such prefix constant strings appear in practice][Cite chapter about frequency analysis] and by the #TODO[very large speedups in matching they can provide][Cite chapter about performance analysis], we conjecture that this is the single *most important optimization* for regex matching in practice. Hence, the prefix acceleration optimization is the primary focus of this work.

To get the proof of correctness for the prefix acceleration optimization we must first formalize this constant-strings-in-regex analysis, called _literal extraction_ (@sec:literals). Then we formalize the notion of looking for those literals in a haystack (@sec:substring-search). And finally, we tackle prefix acceleration proof together with the peculiarities of the PikeVM engine (@sec:prefix-acceleration).

== Literals <sec:literals>

#linden-listing("Engine/Prefix.v", (
  "literal",
  "Nothing",
  "Unknown",
))[Literal definition together with two aliases. The ```rocq string``` type is a list of characters.] <lst:literal>

A literal as defined in @lst:literal is what we extract from a regex $r$. It is defined by its three constructors:

1. ```rocq Exact s``` -- any match of $r$ is exactly the string $s$. For instance, ```rocq Exact "pppac"``` is the literal of ```regex p{3}(a|a)c```,
2. ```rocq Prefix s``` -- any match of $r$ starts with the string $s$. For instance, ```rocq Prefix "abc"``` is the literal of #ex,
3. ```rocq Impossible``` -- the regex $r$ can never match. For instance, the literal of ```regex []``` is ```rocq Impossible```.

Additionally we define two aliases, ```rocq Nothing``` which means $r$ matches exactly the empty string like the regex ```regex ```, and ```rocq Unknown``` which means we cannot tell anything useful about the matches of $r$ like for the regex #ex-unanch.

#linden-listing("Engine/Prefix.v", (
  "prefix",
))[Literal weakening defintion into just the prefix information.] <lst:prefix>

We will commonly want to weaken a literal into just the information of what prefix the represent. The definition is given in @lst:prefix.

#columns(2)[
  #linden-listing("Engine/Prefix.v", (
    "chain_literals",
  ))[Literal chaining definition.] <lst:chain-literals>

  #colbreak()

  #linden-listing("Engine/Prefix.v", (
    "common_prefix",
    "merge_literals",
  ))[Literal merging definition.] <lst:merge-literals>
]

#TODO[Bad layout of the above. Should be one listing]

We must additionally define two important operators on literals. The first one is _chaining_ defined in @lst:chain-literals. It computes the literal resulting from two immediately consecutive literals. If any of the inputs is ```rocq Impossible```, the result is also ```rocq Impossible```. The intuition is that if one of the literals says that no match can exist, then adding anything to the left or right of that does not change this fact. Naturally, chaining is not commutative, it is akin to string contamination. If the left operand is ```rocq Prefix```, then the right operand cannot be used because there might be some unknown characters in between. The second operator is _merging_ defined in @lst:merge-literals. It computes the result of overlapping two literals. If the literals are the same, the result is that literal. Otherwise we must degrade into a ```rocq Prefix``` with the string that is the longest common prefix of both. We can see that in both operators ```rocq Exact``` literals are quite brittle. To get an ```rocq Exact``` literal out of the operators, both operands must be ```rocq Exact```. This is expected, as ```rocq Exact``` literals encode a very strong property about matches.

What follows are a couple of useful lemmas about those operators.

#linden-theorem("Engine/Prefix.v", "chain_literals_assoc")
#linden-theorem("Engine/Prefix.v", "chain_literals_impossible")
#linden-theorem("Engine/Prefix.v", "merge_literals_comm")
#linden-theorem("Engine/Prefix.v", "merge_literals_impossible")

With this setup in place, we can now define the literal extraction function as seen in @lst:extract-literal. A common pattern appearing here is that if the thing we are analyzing can potentially match two different characters, we cannot extract any #underline[certain] literal and so we return with an ```rocq Unknown```.

#TODO[Continue this]
#TODO[Mention the implicit `rer`]
#TODO[Explain `repeat_literal`]

#linden-listing("Engine/Prefix.v", (
  "extract_literal_char",
  "extract_literal",
))[Literal extraction from a character descriptor and from an entire regex.] <lst:extract-literal>

== Substring search <sec:substring-search>

#TODO[Talk about how substring searches are much faster then full blown regex engines. intuition: substring search is a subproblem of regex matching]
