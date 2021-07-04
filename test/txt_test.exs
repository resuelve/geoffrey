defmodule TxtTest do
  use ExUnit.Case

  alias Geoffrey.Parsers.Text
  alias Geoffrey.Rules.Condition

  test "Parsing a condition" do
    condition = Condition.new("eq", ["entity"], "bbva")

    assert [{:ok, condition}] == Text.parse("eq|entity|bbva")
  end

  test "Parsing multiple conditions" do
    c1 = Condition.new("eq", ["entity"], "bbva")
    c2 = Condition.new("neq", ["personal_information", "country"], "mx")

    assert [{:ok, c1}, {:ok, c2}] ==
             Text.parse("eq|entity|bbva\nneq|personal_information.country|mx")
  end
end
