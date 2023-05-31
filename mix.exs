defmodule Geoffrey.MixProject do
  use Mix.Project

  def project do
    [
      app: :geoffrey,
      version: "0.2.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.1"},
      {:ecto, "~> 3.0", optional: true}
    ]
  end
end
