#import "/prelude.typ": *

= Evaluation

To motivate the choice of optimizations for formalization, in @sec:frequency we show that the decisions were guided by the frequency of appearance of certain regex patterns in the wild. Then, in @sec:rust-regex we evaluate the performance benefits of prefix acceleration by comparing three different strategies in Rust's `regex` engine. The strategy proven to be correct in this work was not present in Rust's `regex` before. In some of our benchmarks, it outperforms the existing strategy by up to 20$times$.

== Frequency of patterns in the wild <sec:frequency>

#let data = (
  csv("/regex_frequencies-" + regelk-ref + ".csv", row-type: dictionary)
    .first()
    .pairs()
    .fold((:), (acc, (k, v)) => acc + ((k): int(v)))
)

#let total = data.at("total")
#let parsed = data.at("parsed")

When deciding which optimizations to formalize, it is important to consider which parts need optimizing. One obvious approach is to optimize parts which are slow in practice. This is something that is constantly being done by regex engine developers and researchers. But it is also important to be informed by what kind of regexes are being written by people and used in practice. By analyzing them we can get an idea of which patterns are common and thus worth optimizing for. Since formal verification is a time-consuming process, we focus on optimizations which are most likely to yield performance improvements for real-world regexes.

For that we analyze the large corpora of regexes collected in @regex-in-the-wild1 @regex-in-the-wild2. It consists of #num-fmt(total) regexes scraped from NPM and PyPi packages, StackOverflow posts, RegexLib, and more. To parse them we use the parser from RegElk @linearjsregex, a linear engine and parser for ECMAScript regexes written in OCaml. Once parsed, we analyze the resulting @ast:intro:plural to look for common patterns. From the regexes in the corpora, #percent-fmt(parsed / total) were successfully parsed and analyzed. The rest either contained unsupported features or were malformed. One data point which we do not have is which flags were enabled for each regex. In the analysis we thus assume no flags were enabled. We believe this is a reasonable assumption to make since people tend to leave things at their defaults. For regexes, you must opt in to enable a flag.

#let compute-total(keys) = {
  let normalized-keys = if type(keys) == str { (keys,) } else { keys }
  normalized-keys.map(k => data.at(k)).sum()
}

#let benefits = (
  this-work: rgb("0C7BDC").lighten(50%),
  partial: rgb("FFC20A").lighten(50%),
)

#let row(name, keys, benefits: none, level: 0) = {
  (
    table.cell(fill: benefits)[#{ "| " * level }#name],
    table.cell(fill: benefits, percent-fmt(compute-total(keys) / parsed)),
  )
}

#let extractable = (
  "front_only_literal",
  "back_only_literal",
  "both_literal",
  "impossible_literal",
)

#let fig = [#figure(
  table(
    columns: (110pt, 70pt),
    align: (left, right),
    table.header([*Pattern*], [*Occurrence*]),
    ..row(
      "Extractable literals",
      extractable,
      benefits: benefits.partial,
    ),
    ..row("Front-only", "front_only_literal", level: 1, benefits: benefits.this-work),
    ..row("Back-only", "back_only_literal", level: 1, benefits: benefits.partial),
    ..row("Front and back", "both_literal", level: 1, benefits: benefits.this-work),
    ..row("Impossible literals", "impossible_literal", level: 1, benefits: benefits.this-work),
    ..row("Exact literals", "exact_literal", level: 1, benefits: benefits.this-work),
    ..row("With no asserts", "exact_no_assert_literal", level: 2, benefits: benefits.partial),
    ..row("And no captures", "exact_no_assert_and_no_groups_literal", level: 3, benefits: benefits.partial),
    ..row("Offseted literals", "offset_literal", benefits: benefits.partial),
    ..row([```re ^``` anchored], "anchored", benefits: benefits.this-work),
    ..row([```re $``` anchored], "reverse_anchored", benefits: benefits.partial),
    ..row([```re ^``` and ```re $``` anchored], "double_anchored", benefits: benefits.this-work),
    ..row("No captures", "no_captures"),
  ),
  supplement: "Figure",
  caption: {
    let high = highlight.with(radius: 3pt, extent: 1pt)
    [Occurrences of various regex patterns in the regexes from the corpora, with some #high(fill: benefits.this-work)[rows representing features that are exploited for optimizations in this work] and other #high(fill: benefits.partial)[rows representing features that have only a partial implementation of optimizations in this work].]
  },
) <fig:frequencies>]


#let body = [
  @fig:frequencies shows the frequency of occurrence of patterns among the successfully parsed regexes. We can see that a significant portion (#percent-fmt(compute-total(extractable) / parsed)) of regexes contain meaningful literals that can be extracted. Of those, #percent-fmt((compute-total(extractable) - compute-total(("back_only_literal", "exact_no_assert_literal")) + data.at("exact_no_assert_and_no_groups_literal")) / compute-total(extractable)) can already benefit from the optimizations formalized in this work. We do not count literals such as ```rocq Prefix ""``` which give no useful information. Regexes anchored to the start with ```re ^``` are also quite common (#percent-fmt(data.at("anchored") / parsed)), and thus the optimization for them is also likely to be beneficial in practice. We also note that there are no#assert(data.at("impossible_literal") == 0) regexes for which an ```rocq Impossible``` literal could be extracted. This is expected: we do not anticipate people to write regexes that cannot produce matches. But since adding support for ```rocq Impossible``` literals was simple, we still formalized it in this work. Additionally, we believe that with the help of some rewrites (as noted in margin note @note:impossible-rewrites) the number of ```rocq Impossible``` instances found in regexes will grow, primarily from people accidentally creating unmatchable regexes.

  Exact literals were extracted from #percent-fmt(data.at("exact_literal") / parsed) of the regexes. However, only for #percent-fmt(data.at("exact_no_assert_literal") / data.at("exact_literal")) of them we can perform exact literal optimization. That is because the remaining fraction of regexes contain assertions (lookarounds or anchors) preventing us from optimizing them. Of those regexes with exact literals and no assertions, #percent-fmt((data.at("exact_no_assert_literal") - data.at("exact_no_assert_and_no_groups_literal")) / data.at("exact_no_assert_literal")) have capture groups forcing us to enter the capture reconstruction stage. We believe, however, that most if not all of those regexes that have an exact literal and captures, have captures by mistake. A capture in an exact literal regex is not useful, as the value of those captures will be always the same across all possible matches. By examining those regexes we have identified a common source of mistake where the use of a capture was accidental and the literal characters #hay[(] and #hay[)] were intended to be matched instead. Examples include ```re /header('Content-Location')  /```, ```re /created_at > NOW()/```, and ```re /"CHARACTER VARYING({0})"/```. For each of those, we suspect the parenthesis were intended to be escaped yielding ```re /header\('Content-Location'\)  /```, ```re /created_at > NOW\(\)/```, and ```re /"CHARACTER VARYING\(\{0\}\)"/``` respectively.

  Some entries in the figure represent optimizations which are closely related to those implemented in this work, but are missing a full formalization. This notably includes offseted literals and back optimizations. Completing them requires some additional work which can use the foundations laid in this work. The figure additionally mentions that a very large portion of regexes contain no captures at all (#percent-fmt(data.at("no_captures") / parsed)). This motivates a different line of work, namely around new regex engines. All of those potential extensions are discussed in @sec:future-work.
]

#wrap-it.wrap-content(fig, body, align: right)

== Prefix acceleration in Rust's `regex` <sec:rust-regex>

The `regex` @crate @rust-regex is the official regex library for the Rust programming language. It focuses on providing an efficient and safe implementation of regex engines. Only regex features for which we know a linear-time implementation are supported. Similarly to RE2 @re2, whose architecture served as inspiration for the `regex` crate, it implements a variety of regex engines which are then orchestrated by a single _meta_ engine. It consistently ranks among the fastest linear-time regex engines in benchmarks. It achieves it by employing a large variety of heuristics and optimization which perform well in practice. One of the crucial optimizations it employs is prefix acceleration. In this section we benchmark three different strategies for prefix acceleration using the rebar @rebar benchmarking tool. The benchmarking results underline the importance of this optimization by achieving speedups of up to 600$times$ compared to no prefix acceleration at all. Additionally, we implement our prefix acceleration strategy that has been proven correct in this work and show that in some benchmarks it outperforms the existing implementation by up to 20$times$.

The three prefix acceleration strategies we compare are:

+ Our prefix acceleration presented in @sec:prefix-acceleration.
+ The existing prefix acceleration implemented in Rust's `regex` crate. It is similar to ours, except it does not perform the filtering optimization, only the acceleration is performed.
+ Performing prefix acceleration a single time at the start of matching. It is the strategy described in @sec:one-time-prefix-acceleration. It is the best known prefix acceleration strategy under the black-box assumption.

All of these strategies are implemented in the PikeVM of the `regex` crate. As baseline, we also include results for no prefix acceleration at all.

==== Experimental setup
We modify the `regex` crate and implement the two other prefix acceleration strategies that were not previously present. This fork can be found under #link("https://github.com/epfl-systemf/rust-regex/tree/" + rustregex-ref). We use the rebar @rebar benchmarking tool. Rebar is a benchmarking framework and collection of benchmarks for regex engines. It serves as a trusted source of performance comparisons. We modify the rebar repository to add our modified `regex` crate and enable only benchmarks that test the PikeVM directly. This fork can be found under #link("https://github.com/epfl-systemf/rebar/tree/" + rebar-ref). The benchmarks were run on an idle Macbook Air M1 with 16GB of RAM. The following commands were used to produce the results:

```sh
rebar build -e 'rust/regex/pikevm/(?:noAcc|accOnce|accEmptyStates|accOneAhead)'
rebar measure -e 'rust/regex/pikevm/(?:noAcc|accOnce|accEmptyStates|accOneAhead)' | tee prefilters.csv
```

==== Results
The full report of the results can be found at #link("https://github.com/epfl-systemf/rebar/blob/" + rebar-ref + "/prefilters.md"). The summary of the results is presented in @fig:rust-regex-benchmarks.

#figure(
  table(
    columns: (auto, auto),
    align: (left, right),
    table.header([*Strategy*], [*Geometric mean of speed ratios*]),
    [Our strategy], [*1.03*],
    [Only acceleration (existing implementation)], [1.06],
    [Performing prefix acceleration once], [1.18],
    [No prefix acceleration], [2.42],
  ),
  supplement: "Figure",
  caption: [The summary of all the results of the benchmarks comparing different prefix acceleration strategies. Lower is better.],
) <fig:rust-regex-benchmarks>

This summary gives us an idea of the average performance over a large variety of regexes and haystacks. We first observe that performing even just a single time prefix acceleration yields a significant speedup. This can be attributed to cases where the haystack is large and prefix acceleration reports that no occurrences were found. In these cases we skip running the PikeVM entirely, leading to large speedups. The potential speedup reach upwards of 600$times$, which shows the relative speed of substring search algorithms compared to the PikeVM.

We also see that our strategy performs the best on average. In a few of the worst cases it performed 2$times$ worse than the existing implementation, but in the rest it either performed slightly better or up to 20$times$ better. This shows that the filtering optimization is indeed beneficial in practice. We attribute these regressions to the fact that our strategy is not streaming. We always maintain a counter to the next prefix position. But in some cases the matching could end significantly earlier, leading to wasted work.

The strategy which `regex` currently implements, one where we accelerate multiple times, performs strictly better than doing acceleration just once. This is expected, as performing acceleration does not incur a meaningful overhead. In the benchmarks we observe up to 80$times$ speedups. The degenerative case for one-time acceleration is when the prefix appears very early in the haystack. In that case we skip only a small portion of the haystack. By performing acceleration multiple times we can skip more of the haystack in future accelerations.

These results show the undeniable value of prefix acceleration, even in its simplest form. The strategy developed in this work would be a beneficial contribution to Rust's `regex` crate. It could be an opt-in strategy for users who prioritize speed over streaming characteristics.
