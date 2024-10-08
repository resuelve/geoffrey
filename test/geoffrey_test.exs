defmodule GeoffreyTest do
  use ExUnit.Case
  doctest Geoffrey

  alias Geoffrey.Rule
  alias Geoffrey.Rules.Condition

  test "Condition txt parsing" do
    assert [%Condition{comparator: "gt", compare_to: 18, field: ["age"]}] ==
             Condition.parse("|gt|age|i#18")

    assert [
             %Condition{comparator: "lt", field: ["personal_information", "age"], compare_to: 30}
           ] ==
             Condition.parse("|lt|personal_information.age|i#30")

    assert [
             %Condition{
               comparator: "neq",
               field: ["nested", "2_nested", "3_nested"],
               compare_to: 14.59
             }
           ] ==
             Condition.parse("|neq|nested.2_nested.3_nested|f#14.59")
  end

  test "Condition NL parsing" do
    assert [%Condition{comparator: "gt", compare_to: "18", field: ["age"]}] ==
             Condition.parse("gt age, 18")
  end

  test "Rule generation" do
    condition = %Condition{comparator: "eq", field: ["height"], compare_to: 1.85}

    rule =
      "regla_prueba"
      |> Rule.new("Una prueba")
      |> Rule.set_priority(1)
      |> Rule.set_eval_mode(:any)
      |> Rule.add_condition("|gt|age|i#30")
      |> Rule.add_condition(condition)
      |> Rule.add_action(:example)
      |> Rule.add_action(fn _ -> 2 * 250 end)

    assert rule.name == "regla_prueba"
    assert rule.desc == "Una prueba"
    assert rule.priority == 1

    assert rule.conditions == [
             %Condition{compare_to: 1.85, field: ["height"], comparator: "eq"},
             %Condition{compare_to: 30, field: ["age"], comparator: "gt"}
           ]
  end

  test "Rule eval" do
    input = %{
      "age" => 35,
      "height" => 1.85
    }

    input_2 = %{
      "age" => 30,
      "height" => 1.85
    }

    invalid_input = %{
      "age" => 30,
      "height" => 1.84
    }

    condition = Condition.new("eq", ["height"], 1.85)

    rule =
      "regla_prueba"
      |> Rule.new("Una prueba")
      |> Rule.set_priority(1)
      |> Rule.set_eval_mode(:any)
      |> Rule.add_condition("|gt|age|i#30")
      |> Rule.add_condition(condition)
      |> Rule.add_action(fn x -> Map.put(x, "type", :example) end)
      |> Rule.add_action(fn x -> Map.put(x, "valid?", true) end)

    %Rule{result: result} = Geoffrey.Rule.eval(rule, input)
    assert %{"type" => :example, "valid?" => true} = result

    assert %Rule{valid?: true} = Geoffrey.Rule.eval(rule, input_2)

    assert %Rule{valid?: false} = Geoffrey.Rule.eval(rule, invalid_input)

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
      |> Rule.add_condition("|any|debts.entity|bbva")
      |> Rule.add_action(fn input ->
        Map.put(input, :has_bbva_debt?, true)
      end)

    assert %Rule{result: %{has_bbva_debt?: true}} = Rule.eval(rule1, input)
  end

  test "Test ANY comparator" do
    condition = Condition.new("any", ["value"], 1)

    assert true ==
             Condition.eval(condition, [
               %{"value" => 1, "desc" => "uno"},
               %{"value" => 2, "desc" => "dos"}
             ])
  end

  test "Test IN comparator" do
    condition = Condition.new("in", ["value"], [1, 2, 3])

    assert Condition.eval(condition, %{"value" => 1, "desc" => "uno"})
    assert Condition.eval(condition, %{"value" => 2, "desc" => "dos"})
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
end
