#import "/style/colors.typ": flavor

/// Asserts that a given string does not contain letters which look similar to each other.
/// Similar looking letters may lead to confusion when visualizing text where the individual
/// letter matter.
///
/// - s (str):
/// -> none
#let assert-no-similar-letters(s) = {
  // For each of those, we do not want both to appear in the same string
  let similar_letters = (
    ("p", "q", "b", "d"),
    ("f", "t"),
    ("m", "w"),
    ("n", "u"),
    ("I", "l", "1"),
    ("O", "0"),
    ("S", "5"),
    ("Z", "2"),
    ("h", "b"),
    ("m", "rn"),
  )

  for letters in similar_letters {
    let count = 0

    for letter in letters {
      if s.contains(letter) {
        count = count + 1
      }
    }

    if count > 1 {
      panic("The string " + repr(s) + " contains similar looking letters which may lead to confusion: " + repr(letters))
    }
  }
}

/// A haystack.
///
/// - s (any): The string content of the haystack. If possible to turn into a string, its newlines will be replaced by the "⏎" symbol for better visualization.
/// - seen (int): Number of characters already seen (to be underlined). Works only if `s` can be turned into a string.
/// - position (bool): When true, seen is treated as a single position that should be marked. Works only if `s` can be turned into a string.
/// - match (regex|str): An optional substring to highlight as a match. Works only if `s` can be turned into a string. Mixing with `seen` is not implemented.
/// -> text
#let hay(s, seen: 0, position: false, match: none) = {
  let marker = context box(width: 0pt, place(
    bottom + center,
    dy: 0.6em,
    {
      set text(size: 0.7em)
      $arrow.t$
    },
  ))

  let handle-str(s) = {
    assert-no-similar-letters(s)
    let match-range = if match != none {
      let r = s.match(match)
      if r != none {
        (start: r.start, end: r.end)
      }
    }
    let visual = s.replace("\n", "⏎")

    if match-range != none {
      visual.slice(0, match-range.start)
      highlight(fill: rgb("F6C7FC"), visual.slice(match-range.start, match-range.end))
      visual.slice(match-range.end)
    } else if position {
      visual.slice(0, seen)
      marker
      visual.slice(seen)
    } else {
      underline(visual.slice(0, seen))
      visual.slice(seen)
    }
  }


  let t = if type(s) == content and s.has("text") {
    handle-str(s.text)
  } else if type(s) == str {
    handle-str(s)
  } else {
    s
  }

  text(flavor.colors.green.rgb)["#t"]
}
