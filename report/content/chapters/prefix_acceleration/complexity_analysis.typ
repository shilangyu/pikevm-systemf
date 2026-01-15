#import "/prelude.typ": *

== Complexity analysis <sec:prefix-acceleration-complexity>

We want to ensure that the prefix acceleration optimization does not degrade the asymptotic complexity our regex engines provide. To show no additional asymptotic complexity is incurred, we prove a more general results about prefix acceleration strategies and show that the one proven correct in this work fits into this framework.

#let ssearch = $sans("ssearch")$
#let ssearch-def = $ssearch : sans("string") times sans("string") -> NN$


Let $s s$ be a string and $s$ be a haystack. Let #ssearch-def be a substring search algorithm returning the index of the first occurrence of the substring $s s$ within $s$. If no occurrence exists, it returns some $k > |s|$.

#definition[Streaming-linear substring search][
  We say #ssearch is _streaming-linear_ if its runtime has worst-case complexity $O(|s s| dot |s|)$ and whenever the index of the first occurrence of the substring is $k <= |s|$, then #ssearch finds it in $O(|s s| dot k)$.
]

Intuitively, the streaming-linear property ensures that when finding occurrences we do not needlessly explore more of the haystack than required. Since prefix acceleration calls substring searches multiple times, the weaker _linear_ property of substring searches does not suffice to preserve linearity of prefix acceleration. Luckily, the vast majority of practical substring search algorithms are already streaming-linear.

#definition[Progressing search algorithm][
  An algorithm $T$ over a haystack equipped with #ssearch is called a _progressing search algorithm_ if each $i$-th #ssearch call by $T$ with the haystack advanced to position $p_i$ with a result $k_i$ is such that $p_(i+1) > p_i + k_i$. We set $p_0 = -1$ and $k_0 = 0$.
]

The progressing search property ensures that each #ssearch call makes progress in the haystack and thus #ssearch does not explore the same part of the haystack more than once. Consider the following example trace of a progressing search algorithm $T$. We #underline[underline] the haystack portion on which #ssearch can no longer be called on due to the progression property.

$
                             & : T "is initialized with the haystack" #hay[hello world] \
           #hay[hello world] & : T "calls" #ssearch "at position 0 with substring" #hay[lo] -> 3 \
  #hay(seen: 4)[hello world] & : T "does some work which advances the haystack position by 1" \
  #hay(seen: 4)[hello world] & : T "calls" #ssearch "at position 5 with substring" #hay[o] -> 2 \
  #hay(seen: 8)[hello world] & : T "calls" #ssearch "at position 8 with substring" #hay[rld] -> 0 \
  #hay(seen: 9)[hello world] & : T "terminates"
$

#TODO[Draw under the haystack the position indices]

We are now ready to state and prove the main theorem of this section.

#theorem(
  [Progressing search algorithm complexity],
  [
    Let $T$ be a progressing search algorithm over a haystack $s$ equipped with a streaming-linear substring search #ssearch. Let $Q$ be the runtime complexity of $T$ when #ssearch calls have a cost of $O(1)$. Let $m_i$ be the substring used in the $i$-th #ssearch call. Then, the runtime complexity of $T$ is $O(Q + max_i|m_i| dot |s|)$.
  ],
  proof: [
    Consider an execution of $T$ where #ssearch is called $c$ times with substrings $m_1, m_2, ..., m_c$ and results $k_1, k_2, ..., k_c$. Then the total cost of all #ssearch calls is
    $ O(m_1 k_1) + O(m_2 k_2) + ... + O(m_c k_c) <= O(max_i |m_i| dot (k_1 + k_2 + ... + k_c)) $

    due to #ssearch being streaming-linear. By the progressing search property we have that

    $ k_1 + k_2 + ... + k_c <= |s| $

    Thus, the total cost of all #ssearch calls is $O(max_i |m_i| dot |s|)$. Since calls to #ssearch are only an additive cost, the total runtime complexity of $T$ is $O(Q + max_i |m_i| dot |s|)$, yielding the desired result.
  ],
) <thm:progressing-search-complexity>

We now specialize the theorem above to our prefix acceleration. First, we take #ssearch to be our substring search procedure ```rocq str_search``` defined in @lst:substring-search-class. It differs by returning an optional result rather than always an index. This discrepancy can be easily fixed by seeing a ```rocq None``` result as some $k > |s|$. The unanchored PikeVM is our progressing search algorithm $T$, it calls ```rocq str_search``` in a progressing manner. The substrings used in calls into ```rocq str_search``` are always the extracted literal $ell$ of a regex $r$, thus $max_i|m_i| = |ell|$. But by @thm:literal-size, we get that $|ell| <= |r|$, and so $max_i|m_i| <= |r|$. Finally, to establish $Q$ we have proven in Linden that when treating calls into ```rocq str_serach``` as a constant cost of $O(1)$, the runtime complexity of the unanchored PikeVM is bounded by #TODO[$O(|r| dot |s|)$][Don't we need a proof that `codesize r = O(regex_size r)`?] (proven in #source-permalink(find-statement("Engine/Complexity.v", "pikevm_complexity_unanchored"))). Altogether, by @thm:progressing-search-complexity we get that the total runtime complexity of the prefix accelerated unanchored PikeVM is $O(|r| dot |s| + |ell| dot |s|) <= O(|r| dot |s| + |r| dot |s|) = O(|r| dot |s|)$. Thus, the asymptotic complexity of the PikeVM remains the same when extended with prefix acceleration.

#TODO[Was all this trouble of proving a more general result just to then reduce it to our case worth it?]
