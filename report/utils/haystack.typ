#import "/style/colors.typ": flavor

/// A haystack.
///
/// - s (str | text): The string content of the haystack
/// -> text
#let hay(s) = {
  let t = if type(s) == content and s.has("text") {
    s.text
  } else if type(s) == str {
    s
  }
  assert(t != none, message: "expected str or text content")

  text(flavor.colors.green.rgb)["#t.replace("\n", "⏎")"]
}
