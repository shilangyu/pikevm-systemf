#import "/prelude.typ": *

== Substring search <sec:substring-search>

Substring search is the problem of finding occurrences of a given substring $s s$ in a larger string $s$. This is a well studied problem in computer science, one for which many efficient algorithms exist. Some of the most well known ones like the Rabin-Karp @rabin-karp algorithm runs on average in $O(|s|)$, at worst in $O(|s s| dot |s|)$. Despite having the same complexity as our linear engines, in practice substring search algorithms are much faster and simpler. This makes sense; substring searching is a subproblem of regex matching, and so we can expect specialized algorithms to outperform general ones. Nowadays, highly optimized substring search implementations use @simd:intro further speeding up the search. While SIMD-accelerated regex engines exist @hyperscan, they are much more complex and implement different semantics than the ones we are interested in. Due to substring searches being much faster than general regex engines, we want to leverage them whenever possible in our engine. To that end we will leverage substring searches in prefix acceleration. The correctness of substring searches will yield the correctness of prefix acceleration. Thus, we must first formalize substring searches.

To get started we describe what it means for a string to start with a different string. For this we define the ```rocq starts_with``` inductive seen in @lst:starts-with. We will say that "$s s$ is the prefix of $s$" to mean that $s$ starts with $s s$, or more precisely ```rocq starts_with ss s```. The definition has a base case stating that an empty string is the prefix of any string, and an inductive case stating that if both strings start with the same character and the rest of the first string is the prefix of the rest of the second string, then the first string is the prefix of the second string. One can easily see that this definition is decidable (proof in #source-permalink(find-statement("Engine/Prefix.v", "starts_with_dec"))) and that it defines a @preorder:intro on strings (proof in #source-permalink(find-statement("Engine/Prefix.v", "StartsWithPreOrder"))).

#linden-listing(
  "Engine/Prefix.v",
  "starts_with",
)[Definition of what it means for a string to be a prefix of another.] <lst:starts-with>

Then, we can describe substring search procedures. For this we define a typeclass seen in @lst:substring-search-class. Each instance of this typeclass must provide an implementation of a substring search algorithm together with proofs of three axioms that this search must satisfy. On the high-level, the search function takes two strings, the substring to search $s s$ and the haystack $s$, and returns the earliest position in $s$ where $s s$ appears. If no such position exists, it returns ```rocq None```. This is captured by the three axioms:

#linden-listing("Engine/Prefix.v", "StrSearch")[Substring search typeclass.] <lst:substring-search-class>

+ ```rocq starts_with_ss``` asserts that if the search returns some position, then indeed at that position the haystack starts with the substring,
+ ```rocq no_earlier``` asserts that if the search returns some position, then there is no earlier position where the haystack starts with the substring,
+ ```rocq not_found``` asserts that if the search returns ```rocq None```, then there is no position in the haystack that starts with the substring.

To show that the requirements of this typeclass can be fulfilled, we proceed by showing that we can exhibit an instance of it by implementing a naive brute-force substring search algorithm. Its somewhat cumbersome definition given in @lst:naive-substring-search stems from it being primarily written to facilitate the ease of proofs.

#linden-listing(
  "Engine/Prefix.v",
  ("brute_force_str_search", "BruteForceStrSearch"),
)[Instance of StrSearch through a naive brute-force implementation.] <lst:naive-substring-search>

From here we can prove the three axioms. We do it by proving a more generalized lemma for each of the axioms, which proves the result for any $i$, not only for $i=0$. All proofs follow from inducting over the iteration of ```rocq brute_force_str_search```.

#linden-theorem("Engine/Prefix.v", "brute_force_str_search_starts_with")
#linden-theorem("Engine/Prefix.v", "brute_force_str_search_no_earlier")
#linden-theorem("Engine/Prefix.v", "brute_force_str_search_not_found")

#TODO[The lemmas used by prefix acceleration (str_search_boudn, str_search_succ_cons, str_search_succ_next, str_search_none_next). State if referenced later.]
#TODO[input_search proofs if needed]
