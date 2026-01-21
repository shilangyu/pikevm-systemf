#import "/prelude.typ": *

= Evaluation

To motivate the choice of optimizations chosen for formalization, in @sec:frequency we show that the decisions were guided by the frequency of appearance of certain regex patterns in the wild. Then, in @sec:rust-regex we evaluate the performance benefits of prefix acceleration by comparing three different strategies in Rust's `regex` engine. The strategy proven to be correct in this work was not present in Rust's `regex` before. In some of our benchmarks, it outperforms the existing strategy by up to 20$times$.

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

For that we analyze the large corpora of regexes collected in @regex-in-the-wild1 @regex-in-the-wild2. It consists of #num-fmt(total) regexes scraped from NPM and PyPi packages, StackOverflow posts, RegexLib, and more. To parse them we use the parser from RegElk @linearjsregex, a linear engine and parser for ECMAScript regexes written in OCaml. Once parsed, we analyze the resulting @ast:intro:plural to look for common patterns. From the regexes in the corpora, #percent-fmt(parsed / total) were successfully parsed and analyzed. The rest either contained unsupported features or were malformed. One data point which we do not have is which flags were enabled for each regex. In the analysis we thus assume no flags were enabled. We believe this is a reasonable assumption to make since people tend to leave things at their defaults. For regexes, you must opt-in for a flag to be enabled.

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
    ..row(TODO[No captures][Remove or discuss the need for other engines that do not support captures], "no_captures"),
  ),
  supplement: "Figure",
  caption: {
    let high = highlight.with(radius: 3pt, extent: 1pt)
    [Occurrences of various regex patterns in the regexes from the corpora, with some #high(fill: benefits.this-work)[rows representing features that are exploited for optimizations in this work] and other #high(fill: benefits.partial)[rows representing features that have only a partial implementation of optimizations in this work].]
  },
) <fig:frequencies>]


#let body = [
  @fig:frequencies shows the frequency of occurrence of patterns among the successfully parsed regexes. We can see that a significant portion (#percent-fmt(compute-total(extractable) / parsed)) of regexes contain meaningful literals that can be extracted. Of those, #percent-fmt((compute-total(extractable) - compute-total(("back_only_literal", "exact_no_assert_literal")) + data.at("exact_no_assert_and_no_groups_literal")) / compute-total(extractable)) can already benefit from the optimizations formalized in this work. We do not count literals such as ```rocq Prefix ""``` which give no useful information. Regexes anchored to the start with ```re ^``` are also quite common (#percent-fmt(data.at("anchored") / parsed)), and thus the optimization for them is also likely to be beneficial in practice. We also note that there are no#assert(data.at("impossible_literal") == 0) regexes for which an ```rocq Impossible``` literal could be extracted. This is expected: we do not anticipate people to write regexes that cannot produce matches. But since adding support for ```rocq Impossible``` literals was simple, we still formalized it in this work. Additionally we believe that with the help of some rewrites (as noted in marginnote @note:impossible-rewrites) the number of ```rocq Impossible``` instances found in regexes will grow, primarily from people accidentally creating unmatchable regexes.

  Exact literals were extracted from #percent-fmt(data.at("exact_literal") / parsed) of the regexes. However, only for #percent-fmt(data.at("exact_no_assert_literal") / data.at("exact_literal")) of them we can perform exact literal optimization. That is because the remaining fraction of regexes contain assertions (lookarounds or anchors) preventing us from optimizing them. Of those regexes with exact literals and no assertions, #percent-fmt((data.at("exact_no_assert_literal") - data.at("exact_no_assert_and_no_groups_literal")) / data.at("exact_no_assert_literal")) have capture groups forcing us to enter the capture reconstruction stage. We believe, however, that most if not all of those regexes that have an exact literal and captures, have captures by mistake. A capture in an exact literal regex is not useful, as the value of those captures will be always the same across all possible matches. By examining those regexes we have identified a common source of mistake where the use of a capture was accidental and the literal characters #hay[(] and #hay[)] were intended to be matched instead. Examples include ```re /header('Content-Location')  /```, ```re /created_at > NOW()/```, and ```re /"CHARACTER VARYING({0})"/```. For each of those, we suspect the parenthesis were intended to be escaped yielding ```re /header\('Content-Location'\)  /```, ```re /created_at > NOW\(\)/```, and ```re /"CHARACTER VARYING\(\{0\}\)"/``` respectively.

  Some entries in the figure represent optimizations which are closely related to those implemented in this work, but are missing a full formalization. This notably includes offseted literals and back optimizations. Completing them requires some additional work which can use the foundations laid in this work. The figure additionally mentions that a very large portion of regexes contain no captures at all (#percent-fmt(data.at("no_captures") / parsed)). This motives a different line of work, namely around new regex engines. All of those potential extensions are discussed in @sec:future-work.
]

#wrap-it.wrap-content(fig, body, align: right)

== Prefix acceleration in Rust's `regex` <sec:rust-regex>

The `regex` @crate @rust-regex is the official regex library for the Rust programming language. It focuses on providing an efficient and safe implementation of regex engines. Only regex features for which we know a linear-time implementation are supported. Similarly to RE2 @re2, whose architecture served as inspiration for the `regex` crate, it implements a variety of regex engines which are then orchestrated by a single _meta_ engine. It consistently ranks among the fastest linear-time regex engines in benchmarks. It achieves it by employing a large variety of heuristics and optimization which perform well in practice. One of the crucial optimizations it employs is prefix acceleration. In this section we benchmark three different strategies for prefix acceleration using the rebar @rebar benchmarking tool. The benchmarking results underline the importance of this optimization by achieving speedups of up to 600$times$ compared to no prefix acceleration at all. Additionally, we implement our prefix acceleration strategy that has been proven correct in this work and show that in some benchmarks it outperforms the existing implementation by up to 20$times$.

#TODO[evaluation of prefix acceleration in rust-regex: https://github.shilangyu.dev/pikevm-systemf/meeting-notes/2025_11_05.html]

#TODO[Make reproducible directly from benchmarks rather than copy pasting results and code here. Use rebar to produce analysis reports.
  - Rebar branch: https://github.com/epfl-systemf/rebar/tree/mw/prefix-acc-cmp/
  - Rust regex branch: https://github.com/epfl-systemf/rust-regex/tree/mw/prefix-acc-cmp
]
