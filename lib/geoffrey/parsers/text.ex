defmodule Geoffrey.Parsers.Text do
  @moduledoc """
  Parser para leer las condiciones que se guardan en formato de texto.

  El formato es el siguiente:

  comparator|fieldpath|value

  comparator:  Es el operador binario que vamos a usar para comparar el input y el valor
  fieldpath: Es la llave o llaves (si estuviera anidado) donde se encuentra el valor
             del input a comparar. Para valores anidados se deben separar por puntos.
             Ex. field.path.here

             %{
                 "field": %{
                   "path": %{
                     "here": "somevalue"
                   }
                 }
              }

  value: Es el valor que compararemos contra nuestro input. Este puede esta precedido por i# o f# para indicar que el valor es un entero o un flotante en vez de un string. El tipo del valor por default es string.


  ## Example

      iex> parse("lt|debt_amount|i#1000")
      %Condition{comparator: "lt", field: ["debt_amount"], 1000}

      iex> parse("eq|bank|bbva)
      %Condition{comparator: "eq", field: ["debt", "bank"], "bbva"}


  Para ver todos los operadores ver el modulo `Geoffrey.Rules.Condition.Comparators`

  """

  alias Geoffrey.Rules.Condition

  defguard is_empty(value) when value == "" or is_nil(value)

  @doc """
  Convierte una cadena de caracteres en una o varias condiciones
  """
  @spec parse(String.t()) :: [Condition.t()]
  def parse(condition) do
    condition
    |> String.split("\n")
    |> Enum.map(&parse_condition/1)
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # Crea una condicion a partir de una cadena de caracteres
  @spec parse_condition(String.t()) :: {:ok, Condition.t()} | {:error, String.t()}
  defp parse_condition(condition) do
    [comparator, field, compare_to] = String.split(condition, "|", parts: 3)
    field_path = String.split(field, ".")

    compare_to =
      compare_to
      |> String.split("#")
      |> parse_compare_to()

    case valid_condition?(comparator, field_path, compare_to) do
      true ->
        {:ok, Condition.new(comparator, field_path, compare_to)}

      _ ->
        {:error, condition}
    end
  end

  # Valida que la condicion se haya parseado correctamente
  @spec valid_condition?(any(), [String.t()], any()) :: boolean()
  defp valid_condition?(comparator, field_path, compare_to)
       when is_empty(comparator) or is_empty(field_path) or is_empty(compare_to) do
    false
  end

  defp valid_condition?(_, _, _) do
    true
  end

  # Parsea el valor que se va a comprar en la condicion
  @spec parse_compare_to([String.t()]) :: any()
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

  # Tira un error cuando se intenta comparar una valor con un tipo diferente
  @spec failed_compare_to(String.t(), any()) :: any()
  defp failed_compare_to(type, value) do
    raise "Invalid to_compare #{inspect(value)} is not of type #{type}"
  end
end
