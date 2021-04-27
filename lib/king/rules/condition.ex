defmodule King.Rules.Condition do
  alias King.Rules.Condition.Comparators

  defstruct [
    :comparator,
    :field,
    :compare_to,
    :child_condition
  ]

  @type t :: %__MODULE__{
          comparator: function() | String.t(),
          field: [String.t()],
          compare_to: any(),
          child_condition: King.Rules.Condition.t()
        }

  def new(comparator, field, to_compare, child_condition \\ nil)

  def new(comparator, field, to_compare, child_condition) when is_binary(field) do
    new(comparator, [field], to_compare, child_condition)
  end

  def new(comparator, field, to_compare, child_condition) when is_list(field) do
    %__MODULE__{
      comparator: comparator,
      field: field,
      compare_to: to_compare,
      child_condition: child_condition
    }
  end

  def eval([], _input) do
    true
  end

  def eval([condition | conditions], input) do
    eval(condition, input) and eval(conditions, input)
  end

  def eval(condition, input) when is_function(condition) do
    condition.(input)
  end

  def eval(%__MODULE__{comparator: comparator} = condition, input) when is_function(comparator) do
    do_eval(condition, input, comparator)
  end

  def eval(%__MODULE__{comparator: comparator} = condition, input) when is_binary(comparator) do
    compare_fn = Comparators.get(comparator)
    do_eval(condition, input, compare_fn)
  end

  defp do_eval(condition, input, compare_function) do
    value = find_field(input, condition.field)

    compare_function.(value, condition.compare_to)
  end

  def find_field(input, []) do
    input
  end

  def find_field({_input_key, input}, fields) do
    find_field(input, fields)
  end

  def find_field(input, [field | fields]) when is_map(input) do
    input
    |> Map.get(field)
    |> find_field(fields)
  end

  def find_field([_ | _] = input, [field | _]) do
    Enum.map(input, fn
      input_entity when is_map(input_entity) ->
        Map.get(input_entity, field)

      input_entity ->
        input_entity
    end)
  end

  def find_field(input, _fields) do
    input
  end

  def parse(condition) do
    [condition_type, field, compare_to] = String.split(condition, "|", parts: 3)
    field_path = String.split(field, ">")

    compare_to =
      compare_to
      |> String.split("#")
      |> parse_compare_to()

    %__MODULE__{
      comparator: condition_type,
      field: field_path,
      compare_to: compare_to
    }
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
