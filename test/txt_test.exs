defmodule TxtTest do
  use ExUnit.Case

  alias Geoffrey.Parsers.Text
  alias Geoffrey.Rules.Condition

  test "Parsing a condition" do
    condition = Condition.new("eq", ["entity"], "bbva")

    assert [condition] == Text.parse("eq|entity|bbva")
  end

  test "Parsing multiple conditions" do
    c1 = Condition.new("eq", ["entity"], "bbva")
    c2 = Condition.new("neq", ["personal_information", "country"], "mx")

    assert [c1, c2] == Text.parse("eq|entity|bbva\nneq|personal_information.country|mx")
  end

  test "Parsing IN condition" do
    c1 = Condition.new("any", ["dir", "value"], [1, 2, 3])

    assert [c1] == Text.parse("any|dir.value|i#1,i#2,i#3")
  end

  test "Parsing ANY condition" do
    c1 = Condition.new("any", ["dir", "value"], 1)

    assert [c1] == Text.parse("any|dir.value|i#1")
  end
end
