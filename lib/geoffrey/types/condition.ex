if Code.ensure_loaded?(Ecto.Type) do
  defmodule Geoffrey.Types.Condition do
    @moduledoc """
    Tipo para guardar una condicion en la DB
    Por el momento solo se guarda en modo texto `Geoffrey.Parsers.Text`

    """

    use Ecto.Type

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

    def dump(%{type: type, field: field, comparator: comparator, compare_to: compare_to}) do
      type = get_type_code(type)

      {:ok, "#{comparator}|#{field}|#{type}#{compare_to}"}
    end

    def dump(condition) when is_binary(condition) do
      {:ok, condition}
    end

    def dump(_) do
      :error
    end

    @spec condition_to_string(map) :: String.t()
    defp condition_to_string(%{
           type: type,
           field: field,
           comparator: comparator,
           compare_to: compare_to
         }) do
      type = get_type_code(type)

      "#{comparator}|#{field}|#{type}#{compare_to}"
    end

    # Obtiene el codigo que se agrega antes del value dependiendo el tipo
    @spec get_type_code(any()) :: String.t()
    defp get_type_code("integer"), do: "i#"
    defp get_type_code("float"), do: "f#"
    defp get_type_code(_), do: ""
  end
end
