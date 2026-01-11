#import "/prelude.typ": *

= Literal extraction <sec:literal-extraction>

#let ex = ```re /abc\d+/```
#let ex-unanch = ```re /.*abc\d+/```
#let ex-hay = hay("abc")

One characteristic of regexes which is often exploited for optimization in practice is the knowledge that certain parts of the regex matches literals. Take for example the regex #ex. We can see that any match this regex can produce must contain the constant string #ex-hay. So if a haystack does not contain #ex-hay, we can immediately conclude no match can be found. To speed up looking for matches one can also just look for matches in the neighborhoods of occurrences of #ex-hay in the haystack. Unfortunately, "_searching in the neighborhoods_" is too general of a notion to be useful in practice. Consider ```re /.*abc\d+/```. We still know that any match must contain #ex-hay, but what is the neighborhood of #ex-hay in this case? Because of the ```re /.*/``` preceding the #ex-hay, *everything* before #ex-hay can potentially be part of the match. This means we lost any benefit gained from knowing that there is this constant string there.

Let's go back to the original example of #ex. A more precise information which we can extract here is that not only does any match has to contain #ex-hay, any match *must start* with #ex-hay. This stronger property can be used more directly: first we look for occurrences of #ex-hay and at this position exactly we try to match the regex. If we fail, we can simply move on to the next occurrence. This optimization is commonly referred to as the "prefix acceleration" and is deployed in many real-world regex engines. Informed by the #TODO[frequency at which such prefix constant strings appear in practice][Cite chapter about frequency analysis] and by the #TODO[very large speedups in matching they can provide][Cite chapter about performance analysis], we conjecture that this is the single *most important optimization* for regex matching in practice. Hence, the prefix acceleration optimization is the primary focus of this work.

To get the proof of correctness for the prefix acceleration optimization we must first formalize this constant-strings-in-regex analysis, called _literal extraction_ (@sec:literals). Then we formalize the notion of looking for those literals in a haystack (@sec:substring-search). And finally, we tackle prefix acceleration proof together with the peculiarities of the PikeVM engine (@sec:prefix-acceleration).

#include "literals.typ"
#include "substring_search.typ"
#include "correctness_of_literal_extraction.typ"
