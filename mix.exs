defmodule ReflaxeElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :reflaxe_elixir,
      version: "1.1.5",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      test_paths: ["test/exunit"],
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/fullofcaffeine/reflaxe.elixir"
    ]
  end

  def application do
    [
      # FileSystem is intentionally NOT in extra_applications - it's loaded on-demand
      # This keeps production deployments lightweight since file watching is only needed in dev
      extra_applications: [:logger, :jason]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      # FileSystem is optional - only needed for dev file watching functionality
      # HaxeWatcher checks at runtime if available and provides helpful messages if not
      {:file_system, "~> 1.1", only: :dev}
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
