defmodule TodoApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :todo_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:haxe] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      haxe: [
        hxml_file: "build.hxml",
        source_dir: "src_haxe",
        target_dir: "lib",
        watch: false,  # Disable watcher to avoid process conflicts
        verbose: false
      ]
    ]
  end

  # Configuration for the OTP application.
  def application do
    [
      mod: {TodoApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  defp deps do
    [
      # Add parent project as dependency for Haxe compilation functionality
      {:reflaxe_elixir, path: "../..", only: [:dev, :test]},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics_prometheus_core, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:file_system, "~> 0.2", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["haxe.compile.client", "tailwind todo_app", "esbuild todo_app"],
      "assets.deploy": ["haxe.compile.client", "tailwind todo_app --minify", "esbuild todo_app --minify --tree-shaking=true --drop:debugger --drop:console", "phx.digest"],
      "haxe.compile.client": ["cmd haxe build-client.hxml"]
    ]
  end
end