defmodule ReflaxeElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :reflaxe_elixir,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/fullofcaffeine/reflaxe.elixir"
    ]
  end

  def application do
    extra_apps = [:logger]
    extra_apps = if Mix.env() in [:dev, :test], do: [:jason, :file_system | extra_apps], else: extra_apps
    [
      extra_applications: extra_apps
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:file_system, "~> 0.2"}
    ]
  end

  defp description do
    """
    A Haxe compilation target for Elixir/BEAM enabling gradual typing in Phoenix applications
    with compile-time type-safe Ecto queries and HXX→HEEx template transformation.
    """
  end

  defp package do
    [
      licenses: ["GPL-3.0"],
      links: %{"GitHub" => "https://github.com/fullofcaffeine/reflaxe.elixir"},
      files: ~w(lib mix.exs README* LICENSE*)
    ]
  end
end