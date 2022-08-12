defmodule KinoVix.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_vix,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {KinoVix.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:vix, github: "akash-akya/vix"},
      {:kino, github: "livebook-dev/kino"},
      {:jason, "~> 1.3"}
    ]
  end
end
