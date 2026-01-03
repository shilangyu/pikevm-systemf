/// Removes common leading indentation from all lines in a given string.
/// Additionally it trims redundant whitespace.
///
/// - str (str): string to dedent
/// -> str
#let dedent(str) = {
  let lines = str.split("\n")

  // remove leading empty lines
  while lines.len() > 0 and lines.at(0).trim() == "" {
    let _ = lines.remove(0)
  }

  // remove trailing empty lines
  while lines.len() > 0 and lines.at(-1).trim() == "" {
    let _ = lines.pop()
  }

  // find indent level
  let indent = 0
  for line in lines {
    if line.trim() == "" { continue }

    let count = line.position(regex("\S|$"))
    if indent == 0 or count < indent { indent = count }
  }

  // remove indent
  lines.map(line => if line.len() <= indent { line } else { line.slice(indent) }).join("\n")
}

/// Given a string and a position in that string, returns the line number (1-based) at that position.
///
/// - str (str):
/// - position (int):
/// -> int
#let line-number(str, position) = {
  let lines = str.slice(0, position).split("\n")
  lines.len()
}

/// Lists all definitions, theorems, lemmas, fixpoints, and inductives in a given Linden Rocq file.
///
/// - file (str): Relative path to Linden Rocq source file
/// -> array
#let list-statements(file) = {
  let contents = read("/Linden/" + file)
  let header = regex("(?:[\s--\n]*)(?:Definition|Theorem|Variant|Lemma|Fixpoint|Inductive)\s+([\w\d_']+)[^\.]+\.")

  contents
    .matches(header)
    .map(s => (
      file: file,
      name: s.captures.at(0),
      // remove trailing dot and normalize indentation
      code: dedent(s.text.slice(0, -1)),
      line: (start: line-number(contents, s.start), end: line-number(contents, s.end)),
    ))
}

/// Returns the statement found in `file` with the name `name`.
///
/// - file (str): Linden Rocq source file
/// - name (str): Name of the Rocq statement
#let find-statement(file, name) = {
  let stmt = list-statements(file).find(e => e.name == name)
  assert(stmt != none, message: "Statement '" + name + "' not found in file '" + file + "'")
  stmt
}

/// Generates a GitHub hyperlink to the source code of a statement.
///
/// - stmt ():
/// -> str
#let source-hyperlink(stmt) = {
  let (file, line) = stmt

  (
    "https://github.com/epfl-systemf/Linden/blob/"
      + sys.inputs.LINDEN_REF
      + "/"
      + file
      + "#L"
      + str(line.start)
      + "-L"
      + str(line.end)
  )
}

/// Creates a listing of Linden Rocq code for a given statement.
///
/// - file (str): Linden Rocq source file
/// - name (str): Name of the Rocq statement
/// - lbl (label): Figure label
/// - caption (content): Caption text
/// -> content
#let linden-listing(file, name, lbl, caption) = {
  let stmt = find-statement(file, name)

  [#figure(
      raw(stmt.code, lang: "rocq", block: true),
      caption: caption + [ ] + link(source-hyperlink(stmt))[Source.],
    ) #lbl]
}
