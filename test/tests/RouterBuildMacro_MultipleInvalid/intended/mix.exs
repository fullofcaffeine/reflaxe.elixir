defmodule TestProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_RouterBuildMacro_MultipleInvalid,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
