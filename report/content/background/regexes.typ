#import "/prelude.typ": *
#import "/utils/bnf.typ": *

== Regexes <sec:regex>

#let capture(g, r) = $attach("(", br: #g)#r)$
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
  grid(
    columns: (auto, auto),
    gutter: 4%,
    bnf(
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
    ),
    bnf(
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
    ),
  ),

  caption: [Abstract syntax of Linden regexes],
  supplement: "Figure",
) <fig:regex>

The abstract syntax of Linden regexes is shown in @fig:regex. This syntax slightly differs from the syntax of ECMAScript regexes, but regardless every ECMAScript regex can be expressed using the abstract regex syntax of Linden. We now outline the most important aspects of the syntax and underline the differences between the Linden and ECMAScript representation.

==== Epsilon $epsilon$
The regex that matches the empty string. The ECMAScript regex ```re /|abc/``` is equivalent to $epsilon|"abc"$ in Linden.

==== Capturing group $capture(g, r)$
A @captures:intro numbered by $g$ that captures the substring matched by the regex $r$. In ECMAScript captures are not parametrized by their number. Instead, captures can be either named ```re /(?<name>r)/```, or left unnumbered ```re /(r)/```. We can, however, easily rewrite those captures into numbered ones by incrementally assigning a number starting from 1 for each opening parenthesis of captures from left to right. The ECMAScript regex ```re /e(a(?<in>bc))(f)/``` is equivalent to $e capture(1, "a"capture(2, "bc")) capture(3, "f")$ in Linden.

==== Non-capturing group $chevron.l r chevron.r$
A grouping construct that does not create a capture. The ECMAScript regex ```re /(?:abc)/``` is equivalent to $chevron.l "abc" chevron.r$ in Linden.

==== Quantifier $r{m i n, Delta, gamma}$
Specifies that the regex $r$ is to be repeated at least $m i n in NN$ times, and at most $m i n + Delta$ times. If $Delta$ is $infinity$, then there is no upper bound on the number of repetitions. The parameter $gamma$ specifies whether the quantifier is greedy ($top$) which means it should repeat $r$ as many times as possible or lazy ($bot$) which means it should repeat $r$ as few times as possible. For instance, the ECMAScript regex ```re /a{2,5}b?c*e+?/``` is equivalent to $a{2,3,top}b{0,1,top}c{0,infinity,top}e{1,infinity,bot}$ in Linden.

==== Character descriptor $c d$
Describes sets of characters. If they match something in the haystack, they will always match exactly one character. They can be single literal characters, ranges of characters, unions of character descriptors, the dot (which matches any character except line terminators), character classes (such as word characters, digits, whitespace, Unicode properties), inversion of character descriptors, the set of all characters, or the empty set (it never matches). For instance, the ECMAScript regex ```re /[a-c0-7]\d./``` is equivalent to $[range("a", "c")[range("0", "7")]]#h(0pt)esc("d") dot$ in Linden. For brevity, we will flatten descriptors in $[thin]$, giving us $[range("a", "c")range("0", "7")]$ instead of $[range("a", "c")[range("0", "7")]]$

==== Anchor $a$
Specifies a position in the haystack rather than characters. It is merely an assertion, it does not consume characters. ```re ^``` asserts that we are at the start of the haystack#note[Behavior can be altered by a flag, see @sec:flags.] <note:flag>, and ```re $``` asserts that we are at the end of the haystack@note:flag. ```re \b``` asserts that we are at a word boundary and ```re \B``` that we are not. A word boundary is a position in the haystack where exactly one of the two adjacent characters is a word character and the other character is not, for example ```re /\ba\Bf \bc/``` matches #hay[af c]. The ECMAScript regex ```re /^abc$/``` is equivalent to $\^"abc"\$$ in Linden.

==== Lookaround $la(l k, r)$
A zero-width assertion that $r$ matches or not at the current position. A lookahead ($l k$ is $=$ or $!$) asserts something about the text following the current position, while a lookbehind ($l k$ is $\<=$ or $<#h(0pt)!$) asserts something about the text preceding the current position. Positive lookarounds ($l k$ is $=$ or $\<=$) assert that $r$ has to match, negative lookarounds ($l k$ is $!$ or #box($<#h(0pt)!$)) that it has to not match. The ECMAScript regex ```re /(?=abc)mno(?<!xyz)/``` is equivalent to $la(=, "abc")"mno"la(<!, "xyz")$ in Linden.

Discussion of backreferences is omitted as backreference matching is NP-hard @backref-nphard and here we focus on engines that run in worst-case linear time.

Throughout the report we will tend to use the ECMAScript syntax for regexes for brevity and familiarity, ie. ```re /^this+|syntax*(?=!!!)/```. The theorems will, however, be stated in terms of the Linden abstract regex syntax.


=== Regex size <sec:regex-size>

Throughout this work we will often refer to the size of a regex. Most importantly, the size of a regex plays a role in defining complexity characteristics. We therefore define the precise notion of the size of a regex by @lst:regex-size. From now on, whenever talking about the _"regex size"_ or $|r|$, this is the precise definition we are referring to. As seen, the regex size is equal to the size of the unfolded regex, i.e. one in which quantifier repetitions are unfolded. This does mean that the regex size can be exponentially larger than the size of the textual representation. This can be seen in the example of nested quantification ```regex /((a{5}){5}){5}/```. By just wrapping any regex $r$ with ```regex /(r){n}/``` for some number $n$, we increased its textual size by just $4 + log_10 n$ while the regex size increased by a factor of $n$.

#linden-listing("Semantics/Regex.v", "regex_size")[Regex size definition.] <lst:regex-size>

This unfolded regex definition of the size is used to bound the engine executions, together with the haystack size which is just the length of the input string.

=== Matching semantics <sec:matching-semantics>

We follow the discussion of regexes by outlining the relevant details of the matching semantics. The semantics on which we base our results are known by several names: *backtracking*-, *PCRE*-, or *leftmost-greedy*- semantics. Many regex implementations in standard libraries of programming languages follow these semantics. Examples include Python, Rust, Java, Golang, and of course, ECMAScript#note[... and .NET, Perl, PHP, Dart, Ruby.#note[... aaand C++, Raku, Julia, D, Erlang]]. We describe the important aspects of these semantics below.

==== Priority
#let ex-hay = "aaccc"
A regex could be matched in multiple ways. Consider the regex ```re /(aa|a)c+/``` on the haystack #hay(ex-hay). We could imagine the following results of matching:
- #hay(ex-hay, match: "aaccc"), ```re aa``` chosen in the disjunction and ```re +``` matches `c` three times
- #hay(ex-hay, match: "accc"), ```re a``` chosen in the disjunction and ```re +``` matches `c` three times
- #hay(ex-hay, match: "aac"), ```re aa``` chosen in the disjunction and ```re +``` matches `c` once
However, in our semantics every potential choice during matching has priority assigned to its branches. For disjunction, the alternative that is syntactically written first has priority over the second alternative. In our example that means that the ```re aa``` alternative must be considered for the match. For quantifiers, the priority is given to the branch that tries to match the repeated regex again. The  branch that wants to finish repetitions has lower priority. When using the lazy specifier ($bot$) on quantifiers, the priority is inverted. In our example that means that the ```re c+``` construct must try to match `c` as many times as possible. Hence, only the first listed option (#hay(ex-hay, match: "aaccc")) is a valid match according to our semantics.

==== Leftmost matches
#let ex-r-src = "a+(c|d)"
#let ex-r = raw("/" + ex-r-src + "/", lang: "re")
#let ex-hay = "xxaadyyaac"
When looking for a pattern anywhere in the haystack, multiple matches may exist. In such cases, #underline[the] match which is of relevance to us is the first match, called the leftmost match. For instance, the match of #ex-r in the haystack #hay(ex-hay) is #hay(ex-hay, match: regex(ex-r-src)), not #hay(ex-hay, match: regex(ex-r-src + "$")).

==== Backtracking
During matching when making decisions on which branch to take (disjunction, quantifiers) we follow the priority and leftmost principles outlined above. However, if during matching our choices have led us to a point where no match is found, we backtrack to the last decision and retry with the lower-priority choice. This backtracking is performed until a match is found or all choices are exhausted. For instance, when matching ```re /a+ab/``` on #hay[aaaab], the initial choice of trying to match all #hay[a]s with ```re a+``` would not lead to a match because one more following #hay[a] required by the regex would not be found. So we backtrack and try again by making ```re +``` match one less #hay[a], which would lead to a successful match.

==== Flags <sec:flags>
Matching of a regex can be configured by a handful of boolean flags. These modify the semantics of matching in small but sometimes significant ways. In ECMAScript syntax, these flags appear after the closing `/`. Each flag is represented by a single character. Its presence means that the flag is *enabled*, otherwise it is *disabled*. For instance, the regex ```re /a*c/im``` has the flags `i` and `m` enabled, but all others disabled. Below we mention three of the flags which are of importance for this work.

- *IgnoreCase*, `i` -- when true, the matching is case-insensitive. That means the regex ```re /aB/i``` matches the strings #hay[ab], #hay[aB], #hay[Ab], and #hay[AB], while ```re /aB/``` matches only #hay[aB].
- *Multiline*, `m` -- when true, the anchors ```re ^``` and ```re $``` additionally match respectively the start and the end of a line. That means the regex ```re /^abc$/m``` matches the string #hay("xyz\nabc\nmno"), while ```re /^abc$/``` does not.
- *DotAll*, `s` -- when true, the dot character descriptor matches line terminators as well. That means the regex ```re /a.c/s``` matches the string #hay("a\nc"), while ```re /a.c/``` does not.

In Linden, those flags are stored in the ```rocq RegExpRecord``` record type. An instance of this type will be implicitly available as the variable ```rocq rer```.
