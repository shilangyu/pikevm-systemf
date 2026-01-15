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
/// -> text
#let hay(s) = {
  let repl(s) = s.replace("\n", "⏎")

  let t = if type(s) == content and s.has("text") {
    let res = repl(s.text)
    assert-no-similar-letters(res)
    res
  } else if type(s) == str {
    let res = repl(s)
    assert-no-similar-letters(res)
    res
  } else {
    s
  }

  text(flavor.colors.green.rgb)["#t"]
}
