defmodule KingTest do
  use ExUnit.Case
  doctest King

  alias King.Engine
  alias King.Rule
  alias King.Rules.Condition

  test "Condition parsing" do
    assert %Condition{comparator: "gt", compare_to: 18, field: ["age"]} ==
             King.Rules.Condition.parse("gt|age|i#18")

    assert %Condition{comparator: "lt", field: ["personal_information", "age"], compare_to: 30} ==
             King.Rules.Condition.parse("lt|personal_information>age|i#30")

    assert %Condition{
             comparator: "neq",
             field: ["nested", "2_nested", "3_nested"],
             compare_to: 14.59
           } ==
             King.Rules.Condition.parse("neq|nested>2_nested>3_nested|f#14.59")
  end

  test "Rule generation" do
    condition = %Condition{comparator: "eq", field: ["height"], compare_to: 1.85}

    rule =
      "regla_prueba"
      |> Rule.new("Una prueba")
      |> Rule.set_priority(1)
      |> Rule.add_condition("gt|age|i#30")
      |> Rule.add_condition(condition)
      |> Rule.add_action(:example)
      |> Rule.add_action(fn -> 2 * 250 end)

    assert rule.name == "regla_prueba"
    assert rule.desc == "Una prueba"
    assert rule.priority == 1

    assert rule.conditions == [
             %Condition{compare_to: 1.85, field: ["height"], comparator: "eq"},
             %Condition{compare_to: 30, field: ["age"], comparator: "gt"}
           ]
  end

  test "Rule eval" do
    invalid_input = %{
      "age" => 30,
      "height" => 1.85
    }

    input = %{
      "age" => 35,
      "height" => 1.85
    }

    condition = Condition.new("eq", ["height"], 1.85)

    rule =
      "regla_prueba"
      |> Rule.new("Una prueba")
      |> Rule.set_priority(1)
      |> Rule.add_condition("gt|age|i#30")
      |> Rule.add_condition(condition)
      |> Rule.add_action(:example)
      |> Rule.add_action(fn -> 2 * 250 end)

    assert {true, [500, :example]} = King.Rule.eval(rule, input)
    assert {false, _} = King.Rule.eval(rule, invalid_input)

    input = %{
      "debts" => [
        %{
          "amount" => 175_000,
          "entity" => "bbva"
        },
        %{
          "amount" => 70_000,
          "entity" => "liverpool"
        }
      ],
      "debt_amount" => 245_000,
      "months_without_paying" => 10
    }

    rule1 =
      "regla_1"
      |> Rule.new("Regla #1")
      |> Rule.set_priority(100)
      |> Rule.add_condition("any|debts>entity|bbva")
      |> Rule.add_action(:bbva)

    assert {true, [:bbva]} = Rule.eval(rule1, input)
  end

  test "Test IN comparator" do
    condition = Condition.new("in", ["value"], 1)

    assert true ==
             Condition.eval(condition, [
               %{"value" => 1, "desc" => "uno"},
               %{"value" => 2, "desc" => "dos"}
             ])
  end

  test "Should find field correctly for condition" do
    input = %{
      "f1" => %{
        "f2" => %{
          "f3" => "ok",
          "f4" => "error"
        },
        "f5" => %{
          "f7" => [
            %{"key" => "abc", "value" => 100},
            %{"key" => "xyz", "value" => 0},
            %{"key" => "ijk", "value" => 25}
          ]
        },
        "f6" => "not_okay"
      },
      "f8" => "yay"
    }

    fields1 = ["f1", "f2", "f3"]
    assert get_in(input, fields1) == Condition.find_field(input, fields1)

    fields2 = ["f1", "f5", "f7", "key"]
    assert ["abc", "xyz", "ijk"] == Condition.find_field(input, fields2)

    fields3 = ["f8"]
    assert "yay" == Condition.find_field(input, fields3)
  end

  @tag :engine
  test "Test cascade engine eval" do
    input = %{
      "debts" => [
        %{
          "amount" => 175_000,
          "entity" => "bbva"
        },
        %{
          "amount" => 70_000,
          "entity" => "liverpool"
        }
      ],
      "debt_amount" => 245_000,
      "months_without_paying" => 10,
      "country" => "mx"
    }

    rule1 =
      "bbva"
      |> Rule.new("Para clientes con deudas en bbva")
      |> Rule.set_priority(100)
      |> Rule.add_condition("any|debts>entity|bbva")
      |> Rule.add_condition("in", ["country"], ["mx", "es"])
      |> Rule.add_action(:bbva)

    rule2 =
      "debt_over_240k"
      |> Rule.new("Total de deuda mayor a 240mil pesos MX")
      |> Rule.add_condition("eq", ["country"], "mx")
      |> Rule.add_action(:over_240)

    Engine.new()
    |> Engine.add_rule(rule1)
    |> Engine.add_rule(rule2)
    |> Engine.eval(input)
  end

  @tag :engine
  test "Test first one engine eval" do
    input = %{
      "debts" => [
        %{
          "amount" => 175_000,
          "entity" => "citibanamex"
        },
        %{
          "amount" => 70_000,
          "entity" => "liverpool"
        }
      ],
      "debt_amount" => 245_000,
      "months_without_paying" => 10,
      "country" => "mx"
    }

    rule1 =
      "bbva"
      |> Rule.new("Para clientes con deudas en bbva")
      |> Rule.set_priority(100)
      |> Rule.add_condition("any|debts>entity|bbva")
      |> Rule.add_condition("in", ["country"], ["mx", "es"])
      |> Rule.add_action(:bbva)

    rule2 =
      "debt_over_240k"
      |> Rule.new("Total de deuda mayor a 240mil pesos MX")
      |> Rule.add_condition("gt|debt_amount|#i240000|or")
      |> Rule.add_condition("eq", ["country"], "mx")
      |> Rule.add_action(:over_240)

    Engine.new(:first_one)
    |> Engine.add_rule(rule1)
    |> Engine.add_rule(rule2)
    |> Engine.eval(input)
  end
end
