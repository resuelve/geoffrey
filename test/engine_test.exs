defmodule EngineTest do
  use ExUnit.Case

  alias King.Engine
  alias King.Rule

  test "Test `all` engine eval" do
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
      |> Rule.add_condition("|any|debts.entity|bbva")
      |> Rule.add_condition("in", ["country"], ["mx", "es"])
      |> Rule.add_action(fn set -> Map.put(set, "product_id", 1) end)

    rule2 =
      "debt_over_240k"
      |> Rule.new("Total de deuda mayor a 240mil pesos MX")
      |> Rule.add_condition("eq", ["country"], "mx")
      |> Rule.add_action(fn _ -> :over_240 end)

    Engine.new()
    |> Engine.add_rule(rule1)
    |> Engine.add_rule(rule2)
    |> Engine.eval(input)
  end

  test "Test `any` engine eval" do
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
      |> Rule.add_condition("|any|debts.entity|bbva")
      |> Rule.add_condition("in", ["country"], ["mx", "es"])
      |> Rule.add_action(fn _ -> :bbva end)

    rule2 =
      "debt_over_240k"
      |> Rule.new("Total de deuda mayor a 240mil pesos MX")
      |> Rule.add_condition("|gt|debt_amount|i#240000")
      |> Rule.add_condition("eq", ["country"], "mx")
      |> Rule.add_action(fn _ -> :over_240 end)

    Engine.new(:any)
    |> Engine.add_rule(rule1)
    |> Engine.add_rule(rule2)
    |> Engine.eval(input)
  end

  test "Test `all` engine with result modification" do
    input = %{
      "debts" => [
        %{
          "amount" => 175_000,
          "entity" => "bbva"
        },
        %{
          "amount" => 70_000,
          "entity" => "bbva"
        }
      ],
      "debt_amount" => 245_000,
      "months_without_paying" => 10,
      "country" => "es"
    }

    rule1 =
      "bbva_extra"
      |> Rule.new("Para clientes con deudas en bbva se debe de aumentar la deuda un 110%")
      |> Rule.set_priority(100)
      |> Rule.add_condition("|any|debts.entity|bbva")
      |> Rule.add_condition("in", ["country"], ["mx", "es"])
      |> Rule.add_action(fn result ->
        Map.update(result, "debt_amount", 0, fn debt_amount -> debt_amount * 1.10 end)
      end)

    rule2 =
      "eur_debt_over_25k"
      |> Rule.new("Total de deuda mayor a 25mil pesos EUR")
      |> Rule.add_condition("eq", ["country"], "es")
      |> Rule.add_condition("gte", ["debt_amount"], 250_000)
      |> Rule.add_action(fn result -> Map.put(result, "product_id", 99) end)

    Engine.new()
    |> Engine.add_rule(rule1)
    |> Engine.add_rule(rule2)
    |> Engine.eval(input)
  end
end
