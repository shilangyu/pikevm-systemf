/// Git commit hash of Linden to use in Rocq extraction.
#let linden-ref = sys.inputs.LINDEN_REF
/// Git commit hash of RegElk to use in frequency analysis.
#let regelk-ref = sys.inputs.REGELK_REF
/// Git commit hash of Rust's regex crate used for feature implementations.
#let rustregex-ref = sys.inputs.RUSTREGEX_REF
/// Git commit hash of rebar used for benchmarking.
#let rebar-ref = sys.inputs.REBAR_REF
/// Whether we are rendering in book mode.
#let book = "BOOK" in sys.inputs
/// Whether this is a draft build.
#let draft = not "FINAL" in sys.inputs
