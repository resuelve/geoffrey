defmodule King.Rule do
  alias King.Rules.Condition

  defstruct [
    :name,
    :desc,
    {:priority, 0},
    {:conditions, []},
    {:actions, []}
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          desc: String.t(),
          priority: integer(),
          conditions: [],
          actions: []
        }

  def new(name, desc, priority \\ 0) do
    %__MODULE__{
      name: name,
      desc: desc,
      priority: priority
    }
  end

  def set_priority(rule, priority) when is_integer(priority) do
    %{rule | priority: priority}
  end

  def add_condition(rule, condition) when is_binary(condition) do
    parsed_condition = Condition.parse(condition)
    add_condition(rule, parsed_condition)
  end

  def add_condition(rule, %Condition{} = condition) do
    new_conditions = [condition | rule.conditions]

    %{rule | conditions: new_conditions}
  end

  def add_condition(rule, comparator, field, compare_to) do
    condition = Condition.new(comparator, field, compare_to)

    add_condition(rule, condition)
  end

  def add_action(rule, action) do
    new_actions = [action | rule.actions]

    %{rule | actions: new_actions}
  end

  def eval(rule, input) do
    with true <- eval_conditions(rule, input) do
      {true, run_actions(rule)}
    else
      _ ->
        {false, nil}
    end
  end

  defp eval_conditions(%__MODULE__{conditions: conditions}, input) do
    Enum.all?(conditions, &Condition.eval(&1, input))
  end

  defp run_actions(%__MODULE__{actions: actions}) do
    Enum.map(actions, fn
      value when is_function(value) ->
        value.()

      value ->
        value
    end)
  end
end
