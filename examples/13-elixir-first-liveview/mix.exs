defmodule ElixirFirstLiveview.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_first_liveview,
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
        watch: false,
        verbose: true
      ]
    ]
  end

  def application do
    [
      mod: {ElixirFirstLiveview.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:reflaxe_elixir, path: "../..", runtime: false},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["haxe.compile.tests", "test"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["haxe.compile.client", "esbuild elixir_first_liveview"],
      "assets.deploy": ["haxe.compile.client", "esbuild elixir_first_liveview --minify", "phx.digest"],
      "haxe.compile.tests": ["cmd haxe build-tests.hxml"],
      "haxe.compile.client":
        "haxe.watch --once --hxml build-client.hxml --promote assets/js/_hx_app_tmp.js:assets/js/hx_app.js,assets/js/_hx_app_tmp.js.map:assets/js/hx_app.js.map"
    ]
  end
end
