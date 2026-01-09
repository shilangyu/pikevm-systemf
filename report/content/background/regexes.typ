#import "/prelude.typ": *
#import "/utils/bnf.typ": *

== Regexes <sec:regex>

#let capture(g, r) = $attach("(", br: #g) #r)$
#let esc(e) = $\\ #h(0pt) #e$
#let range(c1, c2) = $#c1 #h(0pt) - #h(0pt) #c2$
#let la(kind, r) = {
  let normalized-kind = if kind == $<!$.body {
    $<#h(0pt)!$
  } else {
    kind
  }
  $(? #h(0pt) #normalized-kind thick #r)$
}

#figure(
  columns(2)[
    #bnf(
      Prod($r$, {
        Or[$epsilon$][Epsilon]
        Or[$c d$][Character descriptor]
        Or[$r_1 r_2$][Sequence]
        Or[$r_1|r_2$][Disjunction]
        Or[$capture(g, r)$][Capturing group]
        Or[$chevron.l r chevron.r$][Non-capturing group]
        Or(esc($g$))[Backreference]
        Or[$r{m i n, Delta, gamma}$][Quantifier]
        Or[$a$][Anchor]
        Or[$la(l k, r)$][Lookaround]
      }),
      Prod($gamma$, {
        Or[$top$][Greedy]
        Or[$bot$][Lazy]
      }),
      Prod($l k$, {
        Or[$=$][Positive lookahead]
        Or[$!$][Negative lookahead]
        Or[$\<=$][Positive lookbehind]
        Or[$< #h(0pt) !$][Negative lookbehind]
      }),
    )

    #colbreak()

    #bnf(
      Prod($c d$, {
        Or[$c$][Single character]
        Or[$[range(c_1, c_2)]$][Range]
        Or[$[c d_1 c d_2]$][Union]
        Or[$dot$][Dot]
        Or[$esc("w")$][$esc("W")$][$esc("d")$][$esc("D")$][$esc("s")$][$esc("S")$][$esc("p"){"property"}$][$esc("P"){"property"}$][Character classes]
        Or[$[\^c d]$][Inversion]
        Or[$[\^]$][All]
        Or[$[thin]$][Empty]
      }),
      Prod($a$, {
        Or[$\^$][Start]
        Or[$\$$][End]
        Or[$esc("b")$][Word boundary]
        Or[$esc("B")$][Non-word boundary]
      }),
    )

  ],
  caption: [Abstract syntax of Linden regexes],
  supplement: "Figure",
) <fig:regex>

#TODO[Fix formatting]

The abstract syntax of Linden regexes is shown in @fig:regex. All ECMAScript regexes can be expressed with this syntax. We now outline the most important aspects of the syntax.

- *Epsilon $epsilon$* -- the regex that matches the empty string. The ECMAScript regex ```regex |abc``` is equivalent to $epsilon|"abc"$ in Linden.
- *Capturing group $capture(g, r)$* -- Defines a @captures:intro numbered by $g$ that captures the substring matched by the regex $r$. In ECMAScript captures are not parametrized by their number. Instead, captures can be either named ```regex (?<name>r)```, or left unnumbered ```regex (r)```. We can, however, easily rewrite those captures into numbered ones by incrementally assigning a number starting from 1 for each opening parenthesis of captures from left to right. The ECMAScript regex ```regex e(a(?<in>bc))(d)``` is equivalent to $e capture(1, "a" capture(2, "bc")) capture(3, "d")$ in Linden.
- *Non-capturing group $chevron.l r chevron.r$* -- A grouping construct that does not create a capture. The ECMAScript regex ```regex (?:abc)``` is equivalent to $chevron.l "abc" chevron.r$ in Linden.
- *Quantifier $r{m i n, Delta, gamma}$* -- Specifies that the regex $r$ is to be repeated at least $m i n in NN$ times, and at most $m i n + Delta$ times. If $Delta$ is $infinity$, then there is no upper bound on the number of repetitions. The parameter $gamma$ specifies whether the quantifier is greedy ($top$) which means it should repeat $r$ as many times as possible or lazy ($bot$) which means it should repeat $r$ as few times as possible. For instance, the ECMAScript regex ```regex a{2,5}b?c*d+?``` is equivalent to $a{2,3,top}b{0,1,top}c{0,infinity,top}d{1,infinity,bot}$ in Linden.
- *Character descriptor $c d$* -- Describes sets of characters. If the match something in the haystack, they will match exactly one character. They can be single literal characters, ranges of characters, unions of character descriptors, the dot (which matches any character except line terminators), character classes (such as word characters, digits, whitespace, Unicode properties), inversion of character descriptors, the set of all characters, or the empty set (it never matches). For instance, the ECMAScript regex ```regex [a-c0-7]\d.``` is equivalent to $[range("a", "c")[range("0", "7")]]#h(0pt)esc("d") dot$ in Linden. For brevity, we will flatten descriptors in $[thin]$, giving us $[range("a", "c")range("0", "7")]$ instead of $[range("a", "c")[range("0", "7")]]$
- *Anchor $a$* -- Specifies a position in the haystack rather than characters. It is merely an assertion, it does not consume characters. The ECMAScript regex ```regex ^abc$``` is equivalent to $\^"abc"\$$ in Linden.
- *Lookaround $la(l k, r)$* -- A zero-width assertion that $r$ matches or not at the current position. A lookahead ($l k$ is $=$ or $!$) asserts something about the text following the current position, while a lookbehind ($l k$ is $\<=$ or $<#h(0pt)!$) asserts something about the text preceding the current position. Positive lookarounds ($l k$ is $=$ or $\<=$) assert that $r$ has to match, negative lookarounds ($l k$ is $!$ or #box($<#h(0pt)!$)) that it has to not match. The ECMAScript regex ```regex (?=abc)def(?<!xyz)``` is equivalent to $la(=, "abc")"def"la(<!, "xyz")$ in Linden.

Discussion of backreferences is omitted as backreference matching is NP-hard @backref-nphard and here we focus on engines that run in worst-case linear time.

#TODO[
  Throughout the report we will tend to use the ECMAScript syntax for regexes for brevity and familiarity, ie. ```regex ^this+|syntax*(?=!!!)```. The theorems will, however, be stated in terms of the Linden abstract regex syntax.
][Make it a nice "Hint" box]
#TODO[Describe semantics and flags and that we can about matching anywhere in the haystack (unanchored)]
