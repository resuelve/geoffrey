defmodule Geoffrey.RuleGroup do
  alias Geoffrey.Rule

  defstruct rules: [],
    valid?: false,
            type: :all,
            result: nil

  @type t :: %__MODULE__{
    rules: [Rule.t()],
    valid?: boolean(),
    type: atom(),
    results: [any()]
  }

  @valid_types ~w(all any)a

  @doc """
  Crea un nuevo grupo de reglas
  """
  @spec new :: __MODULE__.t()
  def new do
    %__MODULE__{type: :any}
  end

  @doc """
  Define las reglas que se usaran en este grupo
  """
  @spec set_rules(__MODULE__.t(), [Rule.t()])
  def set_rules(%__MODULE__{} = engine, rules) do
    %{engine | rules: rules}
  end

  @doc """
  Agrega una regla a la lista de reglas del grupo
  """
  @spec add_rule(__MODULE__.t(), Rule.t()) :: __MODULE__.t()
  def add_rule(%__MODULE__{rules: rules} = engine, rule) do
    updated_rules = [rule | rules]

    %{engine | rules: updated_rules}
  end

  @doc """
  Ordena las reglas por prioridad y las evalua
  """
  @spec eval(__MODULE__.t(), map()) :: 
  def eval(%__MODULE__{} = engine, input) do
    engine
    |> order_rules_by_priority()
    |> eval_rules(input)
  end

  @doc """
  Ordena las reglas por prioridad
  """
  @spec order_rules_by_priority(__MODULE__.t()) :: __MODULE__.t()
  def order_rules_by_priority(%__MODULE__{rules: rules} = engine) do
    ordered_rules = Enum.sort_by(rules, & &1.priority, :desc)
    %{engine | rules: ordered_rules}
  end

  @doc """
  Evalua las reglas del grupo.
  Si el grupo es de tipo `all` todas las reglas deben de evaluar correctamente para
  que el grupo sea valido.
  Si el grupo es de tipo `any` con que alguna regla evalue el grupo sera valido
  """
  @spec eval_rules(__MODULE__.t(), map()) :: __MODULE__.t()
  defp eval_rules(%__MODULE__{type: :all, rules: rules} = engine, input) do
    rules_evaluations = Enum.map(rules, &Rule.eval(&1, input))

    case Enum.all?(rules_evaluations, & &1.valid?) do
      true ->
        %{result: result} = List.last(rules_evaluations)
        %{engine | valid?: true, result: result}

      _ ->
        rule_group
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
