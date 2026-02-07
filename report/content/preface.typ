#import "/prelude.typ": *
#import rustycure: *

#set align(horizon)

Before starting my thesis semester, I was in a state that caused me to have serious doubts about my ability to complete a thesis project. I was experiencing a prolonged period of time where my very privileged life somehow felt so difficult and heavy. I could see real examples of it affecting my work and causing me to have trouble delivering projects. The first tangible proof of that happened in May 2024 when I failed a semester project. From then on, it got only worse. Luckily, this thesis is something I consider to be a great success. In the last months, I saw very clear signs of my old self returning, the me that is able to focus on the work that I so enjoy. It feels good to feel good.

I cannot take much credit for arriving to this point. I credit it to the people that I have been so lucky to be surrounded with. I first want to thank Viktor and Simon for being very understanding of my situation when I failed the semester project. I want to thank all of the people that were by my side when I needed them the most, notably I want to thank Jakob, Grégoire, Biers, Victor, Derya, and most importantly my mom. I want to thank Aurèle and Clément for giving me this opportunity, for the guidance, and for being incredible people to work with. Finally, I want to thank Johanna for your invaluable friendship and for allowing me to be happy again.

#align(
  center,
)[All of the documentation for this thesis (including this report) is available at #text(14pt)[#block[https://github.com/shilangyu/pikevm-systemf]]]


#let qr(url) = {
  pdf.artifact(qr-code(
    url,
    quiet-zone: false,
    dark-color: flavor.colors.text.rgb,
    light-color: flavor.colors.base.rgb,
  ))
  link(url)
}

#let name(s) = {
  set text(weight: 900)
  set align(center + horizon)
  s
}

#set text(size: 9pt)
#grid(
  columns: 4,
  rows: 2,
  gutter: 2em,
  name[Rocq formalization],
  name[Parser for frequency analysis],
  name[Rust code used for experiments],
  name[Benchmarks for regex matching],

  qr("https://github.com/LindenRegex/Linden/tree/" + linden-ref),
  qr("https://github.com/LindenRegex/RegElk/tree/" + regelk-ref),
  qr("https://github.com/LindenRegex/rust-regex/tree/" + rustregex-ref),
  qr("https://github.com/LindenRegex/rebar/tree/" + rebar-ref),
)
