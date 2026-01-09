#import "/style/theorem.typ": *
#import "/env.typ": *
#import "/utils/todo.typ": note

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
  let indent = none
  for line in lines {
    if line.trim() == "" { continue }

    let count = line.position(regex("\S|$"))
    if indent == none or count < indent { indent = count }
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
  let header = regex({
    // include all whitespace before the statement, will be needed for correct dedent
    "(?:[\s--\n]*)"
    // header
    "(Definition|Theorem|Variant|Lemma|Fixpoint|Inductive|Notation)"
    "\s+"
    // name
    "([\w\d_']+)"
    // body
    "((?:[^.]|\.\w)+)\."
  })

  contents
    .matches(header)
    .map(s => (
      file: file,
      kind: s.captures.at(0),
      name: s.captures.at(1),
      // remove trailing dot and normalize indentation
      code: dedent(s.text.slice(0, -1)),
      code-body: dedent(s.captures.at(2)),
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
/// -> link
#let source-hyperlink(stmt) = {
  let (file, line) = stmt

  let url = (
    "https://github.com/epfl-systemf/Linden/blob/"
      + linden-ref
      + "/"
      + file
      + "#L"
      + str(line.start)
      + "-L"
      + str(line.end)
  )

  link(
    url,
    raw(stmt.file + "#" + str(line.start) + "-" + str(line.end)),
  )
}

/// Creates a listing of Linden Rocq code for the given statements.
///
/// - file (str): Linden Rocq source file
/// - names (str): Names of the Rocq statements
/// - caption (content): Caption text
/// -> content
#let linden-listing(file, names, caption) = {
  let stmts = names.map(name => find-statement(file, name))

  figure(
    align(left)[
      #for stmt in stmts {
        stack(
          dir: ltr,
          note(
            source-hyperlink(stmt),
            dy: 0.4em,
            keep-order: true,
          ),
          raw(stmt.code, lang: "rocq", block: true),
        )
      }
    ],
    caption: caption,
    gap: 0pt,
  )
}


#let linden-theorem(file, name) = {
  let stmt = find-statement(file, name)

  theorem(
    name,
    [#note(source-hyperlink(stmt), numbering: none)#raw(stmt.code-body, lang: "rocq"),
    ],
    supplement: stmt.kind,
  )
}
