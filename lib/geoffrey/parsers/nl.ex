defmodule Geoffrey.Parsers.NL do
  @moduledoc """
  Parser de lenguaje natural para crear condiciones para reglas

  Este parser funciona hasta el momento pero se encuentra en trabajo
  y se agregara la documentacion una vez que se revise

  """

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

  @spec parse(String.t()) :: {:ok, Condition.t()} | {:error, String.t()}
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
