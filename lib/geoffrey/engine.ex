defmodule Geoffrey.Engine do
  alias Geoffrey.Rule

  defstruct rules: [],
            type: :all,
            result: nil

  @valid_types ~w(all any)a

  def new do
    %__MODULE__{}
  end

  def new(type) when type in @valid_types do
    %__MODULE__{type: type}
  end

  def add_rule(%__MODULE__{rules: rules} = engine, rule) do
    updated_rules = [rule | rules]

    %{engine | rules: updated_rules}
  end

  def eval(%__MODULE__{} = engine, input) do
    engine
    |> order_rules_by_priority()
    |> eval_rules(input)
  end

  def order_rules_by_priority(%__MODULE__{rules: rules} = engine) do
    ordered_rules = Enum.sort_by(rules, & &1.priority, :desc)
    %{engine | rules: ordered_rules}
  end

  defp eval_rules(%__MODULE__{type: :all, rules: rules} = engine, input) do
    rules_evaluations = Enum.map(rules, &Rule.eval(&1, input))

    case Enum.all?(rules_evaluations, & &1.valid?) do
      true ->
        %{result: result} = List.last(rules_evaluations)
        %{engine | result: result}

      _ ->
        false
    end
  end

  defp eval_rules(%__MODULE__{type: :any, rules: rules} = engine, input) do
    valid_rule =
      Enum.find(rules, fn rule ->
        %Rule{valid?: valid?} = Rule.eval(rule, input)
        valid?
      end)

    case valid_rule do
      nil ->
        false

      %{result: result} = _rule ->
        %{engine | result: result}
    end
  end

  defp eval_rules(_engine, _input) do
    raise "Not implemented"
  end
end
