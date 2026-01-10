/// Git commit hash of Linden to use in Rocq extraction.
#let linden-ref = sys.inputs.LINDEN_REF
/// Whether we are rendering in book mode.
#let book = "BOOK" in sys.inputs
/// Whether this is a draft build.
#let draft = not ("FINAL" in sys.inputs)
