defmodule King.Rule do
  alias King.Rules.Condition

  defstruct [
    :name,
    :desc,
    {:priority, 0},
    {:conditions, []},
    {:actions, []},
    :result,
    {:valid?, true},
    {:errors, []}
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
    parsed_conditions = Condition.parse(condition)

    parsed_conditions
    |> Enum.reject(fn {status, _condition} -> status == :error end)
    |> Enum.reduce(rule, fn {_, condition}, updated_rule ->
      add_condition(updated_rule, condition)
    end)
  end

  def add_condition(rule, [_ | _] = conditions) do
    Enum.reduce(conditions, rule, fn condition, updated_rule ->
      add_condition(updated_rule, condition)
    end)
  end

  def add_condition(rule, %Condition{} = condition) do
    new_conditions = [condition | rule.conditions]

    %{rule | conditions: new_conditions}
  end

  def add_condition(rule, comparator, field, compare_to) do
    condition = Condition.new(comparator, field, compare_to)

    add_condition(rule, condition)
  end

  def add_action(rule, action) when is_function(action) do
    action
    |> :erlang.fun_info()
    |> Keyword.get(:arity)
    |> case do
      1 = _arity ->
        new_actions = [action | rule.actions]

        %{rule | actions: new_actions}

      _ ->
        invalid_action(rule)
    end
  end

  def add_action(rule, _action) do
    invalid_action(rule)
  end

  def eval(rule, input) do
    rule = update_result(rule, input)

    with true <- eval_conditions(rule, input) do
      run_actions(rule)
    else
      _ ->
        invalidate(rule)
    end
  end

  defp eval_conditions(%__MODULE__{conditions: conditions}, input) do
    Enum.all?(conditions, &Condition.eval(&1, input))
  end

  defp run_actions(%__MODULE__{actions: actions} = rule) do
    Enum.reduce(actions, rule, fn action, updated_rule ->
      updated_result = action.(updated_rule.result)
      %{updated_rule | result: updated_result}
    end)
  end

  defp update_result(%__MODULE__{} = rule, data) do
    %{rule | result: data}
  end

  defp invalid_action(rule) do
    rule
    |> add_error("Invalid action is not a function of arity 1")
    |> invalidate()
  end

  defp add_error(rule, error) do
    Map.update(rule, :errors, [], fn errors ->
      [error | errors]
    end)
  end

  defp invalidate(rule) do
    %{rule | valid?: false}
  end
end
