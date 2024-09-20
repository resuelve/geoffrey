if Code.ensure_loaded?(Ecto.Type) do
  defmodule Geoffrey.Types.Condition do
    @moduledoc """
    Tipo para guardar una condicion en la DB
    Por el momento solo se guarda en modo texto `Geoffrey.Parsers.Text`

    """

    use Ecto.Type

    alias Geoffrey.Rules.Condition
    alias Geoffrey.Parsers.Text

    require Logger

    def type do
      {:array, :map}
    end

    def cast(conditions) when is_binary(conditions) do
      {:ok, conditions}
    end

    def cast([_ | _] = conditions) do
      conditions =
        conditions
        |> Enum.map(&condition_to_string/1)
        |> Enum.join("\n")

      {:ok, conditions}
    end

    def cast(_) do
      :error
    end

    def load(conditions) when is_binary(conditions) do
      conditions = Text.parse(conditions)

      {:ok, conditions}
    end

    def dump(%Condition{} = condition) do
      condition_str = condition_to_string(condition)

      {:ok, condition_str}
    end

    def dump(%{type: _, field: _, comparator: _, compare_to: _} = condition) do
      condition_str = condition_to_string(condition)

      {:ok, condition_str}
    end

    def dump(condition) when is_binary(condition) do
      {:ok, condition}
    end

    def dump(_) do
      :error
    end

    @spec condition_to_string(map) :: String.t()
    defp condition_to_string(%Condition{
           comparator: comparator,
           field: field,
           compare_to: compare_to
         }) do
      type =
        compare_to
        |> get_value_type()
        |> get_type_code()

      build_db_string(comparator, field, type, compare_to)
    end

    defp condition_to_string(%{
           type: type,
           field: field,
           comparator: comparator,
           compare_to: compare_to
         }) do
      type = get_type_code(type)

      build_db_string(comparator, field, type, compare_to)
    end

    defp build_db_string(comparator, field, type, compare_to) do
      field = flatten_field(field)
      "#{comparator}|#{field}|#{type}#{compare_to}"
    end

    @spec get_value_type(integer | float | binary) :: String.t()
    defp get_value_type(value) when is_integer(value), do: "integer"
    defp get_value_type(value) when is_float(value), do: "float"
    defp get_value_type(value) when is_binary(value), do: "string"

    # Obtiene el codigo que se agrega antes del value dependiendo el tipo
    @spec get_type_code(any()) :: String.t()
    defp get_type_code("integer"), do: "i#"
    defp get_type_code("float"), do: "f#"
    defp get_type_code(_), do: ""

    defp flatten_field([_ | _] = field) do
      Enum.join(field, ".")
    end

    defp flatten_field(field) when is_binary(field) do
      field
    end
  end
end
