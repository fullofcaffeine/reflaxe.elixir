defmodule TestIntegration.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_integration,
      version: "0.1.0", 
      elixir: "~> 1.14",
      compilers: [:haxe] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
