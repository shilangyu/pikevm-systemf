// Various formatting helpers. Follow the fr-CH locale conventions.

/// Formats an integer by separating the thousands.
///
/// - n (int): Integer to format
/// -> str
#let num-fmt(n) = {
  let s = str(calc.abs(n))
  let out = ""

  // Loop as long as there are more than 3 digits left
  while s.len() > 3 {
    out = h(0.3em) + s.slice(-3) + out
    s = s.slice(0, -3)
  }

  // Add the remaining 1-3 digits and the sign if necessary
  out = s + out
  if n < 0 { "-" + out } else { out }
}

/// Formats a decimal as a percentage with the given precision.
///
/// - d (decimal): Number to format
/// - precision (int): The number of decimals to show
/// -> str
#let percent-fmt(d, precision: 2) = {
  let scaled = calc.abs(d * 100)
  let rounded = calc.round(scaled, digits: precision)
  let parts = str(rounded).split(".")

  // 1. Format the integer part using our previous logic
  let int-part = num-fmt(int(parts.at(0)))

  // 2. Handle the decimal part (with optional padding for trailing zeros)
  let dec-part = if precision > 0 {
    let dec = if parts.len() > 1 { parts.at(1) } else { "" }
    "." + dec + ("0" * (precision - dec.len()))
  } else { "" }

  // 3. Assemble
  let sign = if d < 0 { "-" } else { "" }
  sign + int-part + dec-part + "%"
}
