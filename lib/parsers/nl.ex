defmodule King.Parsers.NL do
  import NimbleParsec

  comparator =
    choice([
      string("eq"),
      string("neq"),
      string("gte"),
      string("gt"),
      string("lte"),
      string("lt"),
      string("in"),
      string("any")
    ])
    |> map({String, :to_atom, []})

  whitespace =
    "\s"
    |> string()
    |> repeat()

  field_path = utf8_string([?a..?z, ?., ?_], min: 1)
  compare_to = utf8_string([not: ?\n], min: 1)
  |> ignore(whitespace)

  eol = string("\n")

  condition =
    comparator
    |> ignore(whitespace)
    |> concat(field_path)
    |> ignore(string(","))
    |> ignore(whitespace)
    |> concat(compare_to)
    |> ignore(optional(eol))

  defparsec(:condition, condition)

  defparsec :rule, condition |> wrap() |> repeat()

end
