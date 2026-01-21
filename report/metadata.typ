#import "/prelude.typ": *

#let title-english = TODO[TITLE ENGLISH][english title]
#let title-french = TODO[TITLE FRENCH][french title]
#let degree = "Master"
#let program = "Computer Science"
#let specialization = "Computer Science Theory"
#let school = "School of Computer and Communication Sciences"
#let examiner = "Nate Foster"
#let supervisors = ("Aurèle Barrière", "Clément Pit-Claudel")
#let author = "Marcin Wojnarowski"
#let start-date = datetime(day: 22, month: 9, year: 2025)
#let submission-date = datetime(day: 23, month: 1, year: 2026)

// TODO: move glossary elsewhere?

// Glossary entries as a dictionary:
// - key: glossary term identifier (used for referencing @key)
// - value:
//   - "short": short form of the term (not capitalized)
//   - "short-plural": plural form of the short term
//   - "long": long form of the term (not capitalized)
//   - "long-plural": plural form of the long term
//   - "description": description of the term
#let glossary = (
  regex: (
    short: "regex",
    short-plural: "regexes",
    long: "regular expression",
    long-plural: "regular expressions",
    description: [A _classical_ regex is a pattern describing a regular language. A _modern_ regex is a pattern used in programming languages that may include features going beyond regular languages, such as backreferences and lookarounds. It is used to find matches and to extract substrings from text.],
  ),
  haystack: (
    short: "haystack",
    short-plural: "haystacks",
    long: "haystack",
    long-plural: "haystacks",
    description: [In the context of regex *matching*, the haystack is the input text in which we search for occurrences of patterns defined by regular expressions. When we say that we want to match the regex ```re /a*b{3}/``` against #hay[abc], the string #hay[abc] is the haystack. Newlines in the haystack are represented with the #hay("\n") character. Already seen characters in the haystack are underlined #hay(seen: 3)[qwerty]. Positions in the haystack are marked with an arrow #hay(position: 4)[qwerty]. Match ranges in the haystack are highlighted #hay(match: "ert")[qwerty].],
  ),
  captures: (
    short: "capture",
    short-plural: "captures",
    long: "capturing group",
    long-plural: "capturing groups",
    description: [A feature in modern @regex:plural that allows parts of the matched text to be captured by a subpatterns and extracted later. They are annotated using parentheses. For instance, given ```re /(a(bc))e/```, there are two capture groups: the outer group captures ```abc```, and the inner group captures ```bc```. When this regex matches the string #hay[abce], the first capture group will contain #hay[abc] and the second will contain #hay[bc].],
  ),
  engine: (
    short: "engine",
    short-plural: "engines",
    long: "regex matching algorithm",
    long-plural: "regex matching algorithms",
    description: [An algorithm used to perform matching of a @regex against a @haystack. It supports a specific subset of regex features and has some performance characteristics. Examples include the PikeVM, LazyDFA, Backtracking.],
  ),
  redos: (
    short: "ReDoS",
    short-plural: "ReDoSs",
    long: "Regular expression Denial of Service",
    long-plural: "Regular expression Denial of Service",
    description: [An exploit of unfavorable regex matching performance characteristics. When a regex comes from user input, it can be used to attack by crafting a regex which makes matching take exponential time. This most commonly affects backtracking @engine:plural which have worst-time exponential runtime.],
  ),
  simd: (
    short: "SIMD",
    short-plural: "SIMDs",
    long: "Single Instruction, Multiple Data",
    long-plural: "Single Instruction, Multiple Data",
    description: [A parallel computing paradigm where a single instruction operates on multiple data points simultaneously. Modern CPUs often support SIMD instructions that can process multiple pieces of data in parallel, speeding up operations by a healthy constant factor.],
  ),
  ast: (
    short: "AST",
    short-plural: "ASTs",
    long: "Abstract Syntax Tree",
    long-plural: "Abstract Syntax Trees",
    description: [A tree representation of the syntactic structure of some source code. Usually some redundant information is omitted, hence the "abstract" part in the name.],
  ),
  crate: (
    short: "crate",
    short-plural: "crates",
    long: "crate",
    long-plural: "crates",
    description: [The name used to describe packages in the Rust ecosystem. Crates are most often published to and downloaded from the #link("https://crates.io/")[crates.io] repository.],
  ),
  preorder: (
    short: "preorder",
    short-plural: "preorders",
    long: "preorder",
    long-plural: "preorders",
    description: [A binary relation that is both reflexive and transitive.],
  ),
  lazy-prefix: (
    short: "lazy prefix",
    short-plural: "lazy prefixes",
    long: "lazy prefix",
    long-plural: "lazy prefixes",
    description: [A regex construct that matches any sequence of characters in a non-greedy manner. It is of the form ```re /[^]*?/```. It is prepended to a regex `r` to find a match for `r` anywhere in the haystack.],
  ),
  program-counter: (
    short: "PC",
    short-plural: "PCs",
    long: "program counter",
    long-plural: "program counters",
    description: [An integer value that indicates the current position of execution within a larger sequence of instructions. Storing it allows resuming execution from that point later.],
  ),
  memo-bt: (
    short: "MemoBT",
    short-plural: "MemoBTs",
    long: "memoized backtracker",
    long-plural: "memoized backtrackers",
    description: [A regex @engine that combines backtracking with memoization to avoid redundant computations. It explores possible matches like a backtracking engine but stores intermediate results to ensure that each unique state is only computed once. It has a $O(|r| dot |s|)$ runtime and space complexity.],
  ),
  black-box: (
    short: "black-box",
    short-plural: "black-boxes",
    long: "black-box",
    long-plural: "black-boxes",
    description: [A model where the internal workings are not known by the user. The only interaction with it are possible through its public interface.],
  ),
)
