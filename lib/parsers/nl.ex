defmodule Geoffrey.Parsers.NL do
  import NimbleParsec

  alias Geoffrey.Rules.Condition

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

  whitespace =
    "\s"
    |> string()
    |> repeat()

  field_path = utf8_string([?a..?z, ?., ?_], min: 1)

  compare_to =
    [not: ?\n]
    |> utf8_string(min: 1)
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

  defparsec(:rule, condition |> wrap() |> repeat())

  def parse(conditions) do
    case rule(conditions) do
      {:ok, [_ | _] = conditions, _, _, _, _} ->
        Enum.map(conditions, fn [comparator, field_path, compare_to] ->
          {:ok, Condition.new(comparator, field_path, compare_to)}
        end)

      _ ->
        {:error, conditions}
    end
  end
end
