defmodule Geoffrey.Rule do
  alias Geoffrey.Rules.Condition

  @typep validation_type :: :all | :any

  @enforce_keys [:name]
  defstruct [
    :name,
    :desc,
    {:validation_type, :all},
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
          validation_type: validation_type(),
          priority: integer(),
          conditions: [],
          actions: []
        }

  @doc """
  Crea una nueva regla con prioridad por default de 0

  ## Examples

      iex> new("rule1", "Some rule")
      %Rule{name: "rule1", desc: "Some rule", priority: 0}

  """
  @spec new(String.t(), String.t(), integer()) :: __MODULE__.t()
  def new(name, desc \\ "", priority \\ 0) do
    %__MODULE__{
      name: name,
      desc: desc,
      priority: priority
    }
  end

  @doc """
  Actualiza la prioridad de una regla. El valor debe ser un numero entero
  """
  @spec set_priority(__MODULE__.t(), integer()) :: __MODULE__.t()
  def set_priority(rule, priority) when is_integer(priority) do
    %{rule | priority: priority}
  end

  @doc """
  Actualiza la prioridad de una regla. El valor debe ser un numero entero
  """
  @spec set_validation_type(__MODULE__.t(), validation_type()) :: __MODULE__.t()
  def set_validation_type(rule, validation_type) when is_integer(validation_type) do
    %{rule | validation_type: validation_type}
  end

  @doc """
  Agrega una condicion a la regla
  """
  @spec add_condition(__MODULE__.t(), String.t() | Condition.t() | [String.t()] | [Condition.t()]) ::
          __MODULE__.t()
  def add_condition(rule, condition) when is_binary(condition) do
    condition
    |> Condition.parse()
    |> Enum.reduce(rule, fn condition, updated_rule ->
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

  @doc """
  Agrega una funcion con arity `1` como accion si la regla es valida. Es arity
  `1` porque toma como parametro el input de la regla.
  Si la accion que se agrega no es una funcion de arity `1` se invalida
  automaticamente la regla.
  """
  @spec add_action(__MODULE__.t(), function()) :: __MODULE__.t()
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

  @doc """
  Evalua una regla
  """
  @spec eval(__MODULE__.t(), map()) :: __MODULE__.t()
  def eval(rule, input) do
    rule = update_result(rule, input)

    with true <- eval_conditions(rule, input) do
      run_actions(rule)
    else
      _ ->
        invalidate(rule)
    end
  end

  # Evalua las condiciones de una regla
  @spec eval_conditions(__MODULE__.t(), map()) :: boolean()
  defp eval_conditions(%__MODULE__{conditions: conditions}, input) do
    Enum.all?(conditions, &Condition.eval(&1, input))
  end

  # Ejecuta las acciones asignadas si la regla es valida
  @spec run_actions(__MODULE__.t()) :: __MODULE__.t()
  defp run_actions(%__MODULE__{actions: actions, valid?: true} = rule) do
    Enum.reduce(actions, rule, fn action, updated_rule ->
      updated_result = action.(updated_rule.result)
      %{updated_rule | result: updated_result}
    end)
  end

  defp run_actions(rule) do
    rule
  end

  # Actualiza el result de una regla
  @spec update_result(__MODULE__.t(), any()) :: __MODULE__.t()
  defp update_result(%__MODULE__{} = rule, new_result) do
    %{rule | result: new_result}
  end

  # Invalida una regla y agrega un error
  @spec invalid_action(__MODULE__.t()) :: __MODULE__.t()
  defp invalid_action(rule) do
    rule
    |> add_error("Invalid action is not a function of arity 1")
    |> invalidate()
  end

  # Agrega un eror a una regla
  @spec add_error(__MODULE__.t(), any()) :: __MODULE__.t()
  defp add_error(rule, error) do
    Map.update(rule, :errors, [], fn errors ->
      [error | errors]
    end)
  end

  # Invalida una regla
  @spec invalidate(__MODULE__.t()) :: __MODULE__.t()
  defp invalidate(rule) do
    %{rule | valid?: false}
  end
end
