#import "/prelude.typ": *

// Running examples for this chapter
#let ex-s = "ababcccccabeww"
#let ex-r-src = "a(b|be)w+"
#let ex-r = raw(lang: "re", "/" + ex-r-src + "/")

#let s = hay.with(ex-s)
