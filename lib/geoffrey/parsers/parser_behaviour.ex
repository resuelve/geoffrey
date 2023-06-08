defmodule Geoffrey.Parsers.ParserBehaviour do
  @moduledoc """
  Define all the required functions that should be implemented
  for a valid parser
  """

  alias Geoffrey.Rules.Condition

  @doc """
  For a given string return all the valid parsed conditions as a list
  and ignore all the invalid ones
  """
  @callback parse(raw_condition :: String.t()) :: [Condition.t()]
end
