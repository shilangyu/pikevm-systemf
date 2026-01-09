#import "/prelude.typ": *

#let titleEnglish = TODO[TITLE ENGLISH][english title]
#let titleFrench = TODO[TITLE FRENCH][french title]
#let degree = "Master"
#let program = "Computer Science"
#let specialization = "Computer Science Theory"
#let school = "School of Computer and Communication Sciences"
#let examiner = "Nate Foster"
#let supervisors = ("Aurèle Barrière", "Clément Pit-Claudel")
#let author = "Marcin Wojnarowski"
#let startDate = datetime(day: 22, month: 9, year: 2025)
#let submissionDate = datetime(day: 23, month: 1, year: 2026)


// Glossary entries as a dictionary:
// - key: glossary term identifier (used for referencing @key)
// - value:
//   - "short": short form of the term (not capitalized)
//   - "shortPlural": plural form of the short term
//   - "long": long form of the term (not capitalized)
//   - "longPlural": plural form of the long term
//   - "description": description of the term
#let glossary = (
  regex: (
    short: "regex",
    shortPlural: "regexes",
    long: "regular expression",
    longPlural: "regular expressions",
    description: [A _classical_ regex is a pattern describing a regular language. A _modern_ regex is a pattern used in programming languages that may include features going beyond regular languages, such as backreferences and lookarounds. It is used to find matches and to extract substrings from text.],
  ),
  haystack: (
    short: "haystack",
    shortPlural: "haystacks",
    long: "haystack",
    longPlural: "haystacks",
    description: [In the context of regex *matching*, the haystack is the input text in which we search for occurrences of patterns defined by regular expressions. When we say that we want to match the regex ```regex a*b{3}``` against #hay[abc], the string #hay[abc] is the haystack.],
  ),
  captures: (
    short: "capture",
    shortPlural: "captures",
    long: "capturing group",
    longPlural: "capturing groups",
    description: [A feature in modern @regex:plural that allows parts of the matched text to be captured by a subpatterns and extracted later. They are annotated using parentheses. For instance, given ```regex (a(bc))d```, there are two capture groups: the outer group captures ```abc```, and the inner group captures ```bc```. When this regex matches the string #hay[abcd], the first capture group will contain #hay[abc] and the second will contain #hay[bc].],
  ),
  engine: (
    short: "engine",
    shortPlural: "engines",
    long: "regex matching algorithm",
    longPlural: "regex matching algorithms",
    description: [An algorithm used to perform matching of a @regex against a @haystack. It supports a specific subset of regex features and has some performance characteristics. Examples include the PikeVM, LazyDFA, Backtracking.],
  ),
  redos: (
    short: "ReDoS",
    shortPlural: "ReDoSs",
    long: "Regular expression Denial of Service",
    longPlural: "Regular expression Denial of Service",
    description: [An exploit of unfavorable regex matching performance characteristics. When a regex comes from user input, it can be used to attack by crafting a regex which makes matching take exponential time. This most commonly affects backtracking @engine:plural which have worst-time exponential runtime.],
  ),
)
