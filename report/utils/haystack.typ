#import "/style/colors.typ": flavor

/// A haystack.
///
/// - s (any): The string content of the haystack. If possible to turn into a string, its newlines will be replaced by the "⏎" symbol for better visualization.
/// -> text
#let hay(s) = {
  let repl(s) = s.replace("\n", "⏎")

  let t = if type(s) == content and s.has("text") {
    repl(s.text)
  } else if type(s) == str {
    repl(s)
  } else {
    s
  }

  text(flavor.colors.green.rgb)["#t"]
}
