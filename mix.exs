defmodule ReflaxeElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :reflaxe_elixir,
      version: "0.0.0-development",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      test_paths: test_paths(),
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
      # HaxeServer uses :crypto for deterministic cookie/cache keys even outside tests.
      # Generated sys.ssl key and signature tests use OTP's :public_key application.
      extra_applications: [:logger, :jason, :crypto, :public_key]
    ]
  end

  defp test_paths do
    case System.get_env("REFLAXE_ELIXIR_TEST_LANE") do
      nil -> ["test/exunit", "test/tooling"]
      "" -> ["test/exunit", "test/tooling"]
      "runtime" -> ["test/exunit"]
      "tooling" -> ["test/tooling"]
      lane -> raise "unknown REFLAXE_ELIXIR_TEST_LANE: #{inspect(lane)}"
    end
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
      files: ~w(lib priv mix.exs README* LICENSE*)
    ]
  end
end
