#import "/prelude.typ": *
#import "data.typ": *

#show: setup

== The unanchored PikeVM <sec:unanchored-pikevm>

We wish to turn the PikeVM into an unanchored engine. Since we also would like to take advantage of prefix acceleration, we must do more than just run the anchored PikeVM with a @lazy-prefix. Instead, we design a new version of the PikeVM which will perform unanchored matching while integrating prefix acceleration directly into its execution model.

We first make an observation that the lazy prefix can be simulated by the PikeVM itself. Recall that the lazy prefix for some regex $r$ simply allows us to try to match $r$ at every position of the haystack while prioritizing the leftmost match. Notice, that to attempt a match at some position in the haystack, the PikeVM must execute the thread initialized to the initial label of the NFA of $r$. Let $l_0$ be the initial label of the NFA (in @fig:pikevm-execution, $alpha$ was the initial label $l_0$). Thus, to run $l_0$ at every position of the haystack, we modify two aspects of the PikeVM's execution model. First, we ensure that $l_0$ is always present in the active set when we start exploring a new position of the haystack. This is done by altering the step of advancing the haystack. Instead of just setting the active set to the current blocked set while clearing the blocked set, we additionally append $l_0$ to the end of the active set. Second, when we run out of both active and blocked threads but still have more haystack positions to explore, we restart the matching by placing $l_0$ into the active set. To preserve the leftmost semantics, we only do this restart if no best match has been found so far.

This simulation effectively resembles the execution model of an anchored PikeVM running with a lazy prefix. However, by doing the simulation manually, we gain more fine grained control allowing us to additionally integrate prefix acceleration. We do so by implementing two kinds of optimizations, *filtering* and *accelerating*. Before running this new unanchored PikeVM, we first extract a literal $ell$ from the regex $r$ using literal extraction defined in @sec:literal-extraction.

==== Filtering
During the simulation of the lazy prefix, we said we want to append $l_0$ each time we advance the haystack. However, if we know the new haystack position cannot possibly be the start of a successful match, we can skip appending $l_0$ completely. @thm:correctness-extract-literal-prefix-contra establishes a concrete condition for when there can be no match. If $ell$ is not the prefix of the current haystack position, we know a match cannot exist starting from here and thus we skip appending $l_0$. This optimization allows us to skip performing work for which we know no results will be produced.

==== Accelerating
Whenever the PikeVM has no more active and blocked threads, we said we want to restart the matching with $l_0$ at the next haystack position. But similarly to filtering, if we know that the next haystack position cannot produce a match, we can skip restarting the matching there. Instead, we jump immediately to the next position where $ell$ is found, and restart with $l_0$ there.

Those two optimizations together allow us to potentially skip large parts of the haystack multiple times thanks to exploiting the internals of the PikeVM. We call this new version of the PikeVM the _unanchored PikeVM_. To our knowledge, the filtering optimization is a novel contribution not implemented by existing real-world engines. The drawback of performing filtering is that we must precompute the next occurrence of $ell$ in advance. This makes this form of prefix acceleration non-streaming. However, the benefits can be substantial if we accept this trade-off. The benefits of filtering are evaluated in @sec:rust-regex.


#let new-color = flavor.colors.teal.rgb
#let new(c) = text(new-color, c)
#let trace = {
  let opti-color = flavor.colors.red.rgb
  set par(leading: 0.3em)
  set math.cancel(cross: true, stroke: opti-color, angle: 45deg)
  show "Filtering": set text(opti-color)
  show "Accelerating": set text(opti-color)

  table(
    columns: (7em, 7em, auto),
    stroke: none,
    inset: 5pt,
    align: left,

    table.vline(x: 1, stroke: 1.5pt),

    table.header(
      [#set align(center)
        *Active*],
      [#set align(center)
        *Blocked*],
      [],
    ),

    ..trace-advance(0, counter: true),
    [$[alpha]$], [$[thin]$], [We initialize the counter to 2.],
    [$[thin]$], [$[beta]$], [],

    ..trace-advance(1, counter: true),
    [$[beta, cancel(new(alpha))]$], [$[thin]$], [Filtering: counter did not reach zero, we skip appending $alpha$.],
    [$[thin]$], [$[gamma, lambda]$], [],

    ..trace-advance(2, counter: true),
    [$[gamma, lambda, new(alpha)]$], [$[thin]$], [Counter reached zero, we append $alpha$ and recompute the counter.],
    [$[lambda, new(alpha)]$], [$[thin]$], [],
    [$[new(alpha)]$], [$[thin]$], [],
    [$[thin]$], [$[new(beta)]$], [This time we produce a new blocked thread.],

    ..trace-advance(3, counter: true),
    [$[new(beta), cancel(new(alpha))]$], [$[thin]$], [Filtering: counter did not reach zero, we skip appending $alpha$],
    [$[thin]$], [$[new(gamma), new(lambda)]$], [],

    ..trace-advance(4, counter: true),
    [$[new(gamma), new(lambda), cancel(new(alpha))]$],
    [$[thin]$],
    [Filtering: counter did not reach zero, we skip appending $alpha$],
    [$[new(lambda)]$], [$[thin]$], [],
    [$[thin]$], [$[thin]$], [],

    ..trace-advance(9, counter: true),
    [$[new(alpha)]$], [$[thin]$],
    table.cell(
      rowspan: 2,
    )[Accelerating: we had no more active or blocked threads, we jump 5 positions ahead and recompute the counter],

    table.cell(colspan: 2, align: center)[$dots.v$],
    table.cell(colspan: 2, align: center)[*This leads to a match!*], [],
  )
}

#wideblock[
  #figure(
    grid(
      columns: (auto, auto),
      gutter: 1em,
      ex-r-nfa, trace,
    ),
    supplement: "Figure",
    caption: [Left: the NFA of the regex #ex-r. Right: execution trace of the unanchored PikeVM with the extracted literal $ell = #```rocq Prefix "ab"```$ on the haystack #s(). #new[We color-code new threads previously not created by the anchored PikeVM.]],
  ) <fig:unanchored-pikevm-execution>
]

To implement these optimizations we augment the PikeVM state with a counter that indicates in how many characters we will find $ell$ in the haystack. This counter's value will be always obtained from running the substring search procedure defined in @sec:substring-search. Each time we advance the haystack position, we decrement this counter by one. If the counter is non-zero we may perform filtering by not appending $l_0$ to the active set. If the counter is zero, we must append $l_0$ and compute the new value of the counter. To perform acceleration, when we have no more active and blocked threads we advance the haystack position by the value of the counter and recompute the counter. We illustrate this new execution model by revisiting our running example and showing the execution trace of this unanchored PikeVM in @fig:unanchored-pikevm-execution. For our regex #ex-r, the literal $ell$ is ```rocq Prefix "ab"``` and thus each match must start with the prefix #hay[ab].
