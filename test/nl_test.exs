defmodule NLTest do
  use ExUnit.Case

  alias Geoffrey.Parsers.NL

  test "Should return error if condition is badly typed" do
    assert {:error, _} = NL.parse("WHAT OMG BBQ")
  end

  test "Test condition parsing" do
    condition1 = "eq data.field.something, 10.5"
    condition2 = "any data.field.entity, bbva"

    assert {:ok, ["eq", "data.field.something", "10.5"], _, _, _, _} = NL.condition(condition1)
    assert {:ok, ["any", "data.field.entity", "bbva"], _, _, _, _} = NL.condition(condition2)
  end

  test "Rule parsing" do
    c1 = "gte debt_amount, 120000"
    c2 = "any debts.type, bancaria"
    rule = "#{c1}\n#{c2}"

    assert {:ok, ["gte", "debt_amount", "120000"], _, _, _, _} = NL.condition(c1)
    assert {:ok, ["any", "debts.type", "bancaria"], _, _, _, _} = NL.condition(c2)

    assert {:ok, [["gte", "debt_amount", "120000"], ["any", "debts.type", "bancaria"]], _rest, _,
            _, _} = NL.rule(rule)
  end
end
