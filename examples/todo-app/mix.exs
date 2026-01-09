defmodule TodoApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :todo_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      # Ensure Haxe server-side code compiles as part of `mix compile`
      compilers: [:haxe] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      haxe: [
        # Use the full server build to ensure all modules are generated together.
        # Legacy "multipass" / micro-pass build configs were removed during cleanup.
        # If you need to reference them, use git history.
        hxml_file: "build-server.hxml",
        source_dir: "src_haxe",
        target_dir: "lib",
        # Keep watcher disabled here; we start a watcher via Endpoint watchers (dev.exs)
        watch: false,
        verbose: false
      ]
    ]
  end

  # Configuration for the OTP application.
  def application do
    [
      mod: {TodoApp.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets, :ssl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:e2e), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  defp deps do
    [
      # Add parent project as dependency for Haxe compilation functionality
      {:reflaxe_elixir, path: "../..", only: [:dev, :test, :e2e]},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics_prometheus_core, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.20"},
      {:hackney, "~> 1.25"},
      # Webserver stack pinned for OTP/toolchain compatibility (see docs/06-guides/TODOAPP_COWBOY_TOOLCHAIN.md)
      {:plug_cowboy, "~> 2.7.5", override: true},
      {:cowboy, "~> 2.14.2", override: true},
      {:cowlib, "~> 2.16.0", override: true},
      {:ranch, "~> 2.2", override: true},
      {:file_system, "~> 1.1", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: [
        "deps.get",
        # Install toolchain deps for this example app:
        # - root: lix (Haxe toolchain manager) + Playwright
        # - assets: Phoenix JS deps for esbuild bundling
        "cmd npm install --no-audit --no-fund",
        "cmd --cd assets npm install --no-audit --no-fund",
        "ecto.setup",
        "assets.setup",
        "assets.build"
      ],
      # One-liner for local dev: ensure DB exists + migrated, then start Phoenix with watchers.
      dev: ["ecto.create", "ecto.migrate", "phx.server"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      # Tests rely on compiled Haxe app; compile Haxe-authored ExUnit modules before `mix test`.
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "haxe.compile.tests", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["haxe.compile.client", "tailwind todo_app", "esbuild todo_app"],
      "assets.deploy": ["haxe.compile.client", "tailwind todo_app --minify", "esbuild todo_app --minify --tree-shaking=true --drop:debugger --drop:console", "phx.digest"],
      "haxe.compile.client": ["cmd haxe build-client.hxml"],
      "haxe.compile.tests": ["cmd haxe build-tests.hxml"]
    ]
  end
end
