#import "/prelude.typ": *

== Literals <sec:literals>

The literal extraction phase is a form of static analysis of the syntactic structure of the regex. As such, various implementations of the analysis could produce varying degrees of preciseness in the result. For instance, we said that for the example of ```re /abc\w+/``` we can extracted a prefix of #hay[abc]. But a less precise yet still correct analysis could only extract the prefix #hay[a]. In this work we implement an analysis resembling abstract interpretation that tries to extract as much information as possible. When giving examples of what an extracted literal of some regex could be, we always mean the most precise literal that our analysis can extract.

#linden-listing("Engine/Prefix.v", (
  "literal",
  "Nothing",
  "Unknown",
))[Literal definition together with two aliases. The ```rocq string``` type is a list of characters.] <lst:literal>

A literal as defined in @lst:literal is what we extract from a regex $r$. It is defined by its three constructors:

+ ```rocq Exact s``` -- any match of $r$ is exactly the string $s$. For instance, the literal of ```re /p{3}(a|a)c/``` is ```rocq Exact "pppac"```,
+ ```rocq Prefix s``` -- any match of $r$ starts with the string $s$. For instance, the literal of ```re /abc\w+/``` is ```rocq Prefix "abc"```,
+ ```rocq Impossible``` -- the regex $r$ can never match. For instance, the literal of ```re /[]/``` (empty character class) is ```rocq Impossible```.

Additionally we define two aliases, ```rocq Nothing``` (standing for ```rocq Exact ""```) which means $r$ matches exactly the empty string like the empty regex ```re //```, and ```rocq Unknown``` (standing for ```rocq Prefix ""```) which means we cannot tell anything useful about the matches of $r$ like for the regex ```re /.*abc\w+/```.

#linden-listing("Engine/Prefix.v", "prefix")[Literal weakening defintion into just the prefix information.] <lst:prefix>

We will often want to weaken a literal into just the information of what prefix it represents. The definition is given in @lst:prefix.

#linden-listing("Engine/Prefix.v", (
  "chain_literals",
  "common_prefix",
  "merge_literals",
))[Literal chaining and merging definitions.] <lst:chain-merge-literals>

We must additionally define two important operators on literals. The first one is _chaining_ defined in @lst:chain-merge-literals. It computes the literal resulting from joining two immediately consecutive literals, most commonly from a sequence. If any of the inputs is ```rocq Impossible```, the result is also ```rocq Impossible```. The intuition is that if one of the literals says that no match can exist, then adding anything to the left or right of that does not change this fact. Naturally, chaining is not commutative, it is akin to string concatenation. If the left operand is ```rocq Prefix```, then the right operand cannot be used because there might be some unknown characters in between. The second operator is _merging_ defined in @lst:chain-merge-literals. It computes the result of joining two overlapping literals, most commonly from a disjunction. If the literals are the same, the result is that literal. Otherwise we must degrade into a ```rocq Prefix``` with the string that is the longest common prefix of both. We can see that in both operators ```rocq Exact``` literals are quite brittle. To get an ```rocq Exact``` literal out of the operators, both operands must be ```rocq Exact```. This is expected, as ```rocq Exact``` literals encode a very strong property about matches.

What follows are a couple of useful lemmas about those operators.

#linden-theorem("Engine/Prefix.v", "chain_literals_assoc")
#linden-theorem("Engine/Prefix.v", "chain_literals_impossible")
#linden-theorem("Engine/Prefix.v", "merge_literals_comm")
#linden-theorem("Engine/Prefix.v", "merge_literals_impossible")

We need one more definition before we can fully define literal extraction. @lst:repeat-literal defines the operation of repeatedly chaining a literal $l$ for $n$ times with a base case of a literal $b a s e$ which will be used at the very end of the chaining. For example, ```rocq repeat_literal (Exact "a") (Prefix "b") 3``` reduces to

#{
  show math.equation: set text(size: 0.7em)
  $
    & attach(~>, tr: *) #```rocq chain_literals (Exact "a") (chain_literals (Exact "a") (chain_literals (Exact "a") (Prefix "b")))``` \
    & ~> #```rocq chain_literals (Exact "a") (chain_literals (Exact "a") (Prefix "ab"))``` \
    & ~> #```rocq chain_literals (Exact "a") (Prefix "aab")``` \
    & ~> #```rocq Prefix "aaab"```
  $
}

#linden-listing("Engine/Prefix.v", "repeat_literal")[Repeated chaining of a literal.] <lst:repeat-literal>

With this setup in place, we can now define the literal extraction function as seen in @lst:extract-literal. A common pattern appearing here is that if the thing we are analyzing can potentially match two different characters, we cannot extract any #underline[certain] literal and so we return with an ```rocq Unknown```. This is the case with character classes like ```re /\d/``` (```rocq CdDigits```), which can match as many as ten characters. The only case which gives us the ```rocq Impossible``` literal is the empty character class ```re /[]/```, which can never match any character#note[This analysis could be extended to find more ```rocq Impossible``` cases, such as ```re /(?=b)a/```. This however can be instead handled by a regex-equivalence rewrite pass, which would turn that regex into ```re /[]/``` and then would be detected by the literal extraction.]<note:impossible-rewrites>. ```rocq Exact``` literals are produced one character at the time from character descriptors; the single constant character like ```re /c/```, ranges over one character like ```re /[c-c]/```, and unions of character descriptors which all match the same character like ```re /[cc-c]/```. Whenever we want combine literals from different parts of the regex, we either want to chain them (```rocq Sequence```, ```rocq Quantified```) or merge them (```rocq Disjunction```, ```rocq CdUnion```).

Depending on $Delta$, we must distinguish between the cases of quantifiers. If $Delta = 0$, this quantification has a fixed number of repetitions, so we can analyze it just as if the quantified regex was repeated that many times. This will allow us to extract ```rocq Exact``` literals from regexes like ```re /a{4}/```. If $Delta > 0$, we can at best extract a ```rocq Prefix``` literal, as the number of repetitions is not fixed. This will allow us to extract ```rocq Prefix "aaaa"``` from ```re /a{4,5}/```. Computing this literal is done using @lst:repeat-literal with the repetition count equal to $m i n$ and the base case differing based on whether $Delta$ is zero or not.

#linden-listing("Engine/Prefix.v", (
  "extract_literal_char",
  "extract_literal",
))[Literal extraction from a character descriptor and from an entire regex.] <lst:extract-literal>

The entire extraction must be guarded on the `ignoreCase` flag (see @sec:flags). If this flag is set, we cannot extract any #underline[certain] literals from the regex, rendering this optimization useless. This weakness can be addressed by extracting multiple literals per regex rather than just one. More on this improvement can be found in @sec:future-work.

One could extract literals from backreferences by expanding them into the literal extracted from the referenced capture. Then, the literal of ```re /(abc)\1/``` would be ```rocq Exact "abcabc"```.  However, since in this work we are interested in linear time regex engines, and linear engines do not support backreferences, we do not implement this feature. With the help of a few lemmas,

#linden-theorem("Engine/Prefix.v", "chain_literals_length") <thm:chain-literals-length>
#linden-theorem("Engine/Prefix.v", "repeat_literal_length") <thm:repeat-literal-length>
#linden-theorem("Engine/Prefix.v", "merge_literals_length") <thm:merge-literals-length>

we show that the length of the extracted literal is bounded by the size of the regex.

#linden-theorem("Engine/Prefix.v", "extract_literal_size_bound", proof: [
  Induction on $r$, using @thm:chain-literals-length, @thm:repeat-literal-length, and @thm:merge-literals-length where applicable.
]) <thm:literal-size>
