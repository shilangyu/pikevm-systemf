#import "/utils/todo.typ": *

#let titleEnglish = TODO[TITLE ENGLISH][english title]
#let titleFrench = TODO[TITLE FRENCH][french title]
#let degree = "Master"
#let program = "Computer Science"
#let specialization = "Computer Science Theory"
#let school = "School of Computer and Communication Sciences"
#let examiner = TODO[EXAMINER NAME][examiner name]
#let supervisors = ("Aurèle Barrière", "Clément Pit-Claudel")
#let author = "Marcin Wojnarowski"
#let startDate = datetime(day: 22, month: 9, year: 2025)
#let submissionDate = datetime(day: 23, month: 1, year: 2026)

#let glossary = (
  regex: (
    short: "Regex",
    shortPlural: "Regexes",
    long: "Regular expression",
    longPlural: "Regular expressions",
    description: [A _classical_ regex is a pattern describing a regular language. A _modern_ regex is a pattern used in programming languages that may include features going beyond regular languages, such as backreferences and lookarounds. It is used to find matches and to extract substrings from text.],
  ),
)
