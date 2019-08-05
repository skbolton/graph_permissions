defmodule GraphPermissions.MixProject do
  use Mix.Project

  def project do
    [
      app: :graph_permissions,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GraphPermissions.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bolt_sips, "~> 2.0.0-rc"},
      {:jason, "~> 1.1"},
      {:uuid, "~> 1.1"}
    ]
  end
end
