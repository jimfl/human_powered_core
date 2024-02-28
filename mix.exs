defmodule HumanPowered.MixProject do
  use Mix.Project

  def project do
    [
      app: :human_powered,
      version: "0.1.0",
      elixir: "~> 1.16",
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
      {:mdex, "~> 0.1.13"},
      {:yaml_elixir, "~> 2.9"},
      {:toml, "~> 0.7.0"}
    ]
  end
end
