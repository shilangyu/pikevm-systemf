#import "/prelude.typ": *
#import fletcher: *

// Running examples for this chapter
#let ex-s = "ababcccccabeww"
#let ex-r-src = "a(?:b|be)w+"
#let ex-r-prefix = "ab"
#let ex-r = raw(lang: "re", "/" + ex-r-src + "/")

#let s = hay.with(ex-s)

#let setup(body) = {
  show math.alpha: math.bold
  show math.beta: math.bold
  show math.gamma: math.bold
  show math.delta: math.bold
  show math.lambda: math.bold

  body
}


#let ex-r-nfa = diagram(
  node-stroke: 1.5pt,
  spacing: 2.4cm,
  label-size: 1em,

  node((0, 0), [$alpha$], name: <alpha>),
  node((0, 1), [$beta$], name: <beta>),
  node((0.5, 1.5), [$lambda$], name: <lambda>),
  node((0, 2), [$gamma$], name: <gamma>),
  node((0, 3), [$delta$], name: <delta>, extrude: (-2.5pt, 0pt)),

  edge((0, -0.5), <alpha>, "-|>", stroke: 1pt),
  edge(<alpha>, <beta>, "-|>", stroke: 1pt, label: hay[a], label-pos: 0.4),
  edge(
    <beta>,
    <gamma>,
    stroke: 1pt,
    label: text(fill: blue, [*1*]),
    label-pos: 0.1,
  ),
  edge(
    <beta>,
    <gamma>,
    "-|>",
    stroke: 1pt,
    label: hay[b],
    label-pos: 0.45,
  ),
  edge(
    <beta>,
    <lambda>,
    stroke: 1pt,
    label: text(fill: blue, [*2*]),
    label-pos: 0.1,
  ),
  edge(
    <beta>,
    <lambda>,
    "-|>",
    stroke: 1pt,
    label: hay[b],
  ),
  edge(<lambda>, <gamma>, "-|>", stroke: 1pt, label: hay[e], label-side: left, label-pos: 0.4),
  edge(<gamma>, <delta>, "-|>", stroke: 1pt, label: hay[w], label-pos: 0.4),
  edge(<delta>, <delta>, "-|>", stroke: 1pt, bend: -130deg, label: hay[w]),
)

#let trace-advance(pos, counter: false) = (
  table.cell(colspan: 2, align: horizon)[#line(length: 100%, stroke: (
    dash: if pos == 0 { "solid" } else { "dashed" },
    thickness: 1.5pt,
  ))],
  s(seen: pos, position: pos)
    + if counter {
      let p = ex-s.slice(pos + 1).position(ex-r-prefix)
      let c = if p == none {
        $infinity "(no more occurrences)"$
      } else {
        p + 1
      }
      $quad "counter" = #c$
    } else {
      ""
    },
)
