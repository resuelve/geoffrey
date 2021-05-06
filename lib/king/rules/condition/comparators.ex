defmodule King.Rules.Condition.Comparators do
  def get("eq") do
    &Kernel.==/2
  end

  def get("neq") do
    &Kernel.!=/2
  end

  def get("gt") do
    &Kernel.>/2
  end

  def get("gte") do
    &Kernel.>=/2
  end

  def get("lt") do
    &Kernel.</2
  end

  def get("lte") do
    &Kernel.<=/2
  end

  def get("in") do
    fn
      value, compare_to when is_list(value) ->
        compare_to in value

      _, _ ->
        false
    end
  end

  def get("any") do
    fn
      values, compare_to when is_list(values) ->
        Enum.any?(values, fn v -> v == compare_to end)

      _, _ ->
        false
    end
  end
end
