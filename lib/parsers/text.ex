defmodule King.Parsers.Text do
  alias King.Rules.Condition

  defguard is_empty(value) when value == "" or is_nil(value)

  def parse(condition) do
    [comparator, field, compare_to] = String.split(condition, "|", parts: 3)

    field_path = String.split(field, ">")

    compare_to =
      compare_to
      |> String.split("#")
      |> parse_compare_to()

    case validate_parse(comparator, field_path, compare_to) do
      true ->
        [{:ok, Condition.new(comparator, field_path, compare_to)}]

      _ ->
        {:error, condition}
    end
  end

  defp validate_parse(comparator, field_path, compare_to)
       when is_empty(comparator) or is_empty(field_path) or is_empty(compare_to) do
    false
  end

  defp validate_parse(_, _, _) do
    true
  end

  # Parsea el valor que se va a comprar en la condicion
  # @spec parse_compare_to([String.t(), String.t()]) :: any()
  defp parse_compare_to(["i", value]) do
    case Integer.parse(value) do
      {parsed_value, _} ->
        parsed_value

      _ ->
        failed_compare_to("int", value)
    end
  end

  defp parse_compare_to(["f", value]) do
    case Float.parse(value) do
      {parsed_value, _} ->
        parsed_value

      _ ->
        failed_compare_to("float", value)
    end
  end

  defp parse_compare_to([value]) do
    value
  end

  defp failed_compare_to(type, value) do
    raise "Invalid to_compare #{value} is not of type #{type}"
  end
end
