defmodule PhoenixhxLiveReact.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenixhx_live_react,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:haxe, :phoenix_live_view] ++ Mix.compilers(),
      haxe: [
        hxml_file: "build.hxml",
        source_dir: "src_haxe",
        target_dir: "lib/phoenixhx_live_react_hx",
        watch: Mix.env() == :dev
      ],
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PhoenixhxLiveReact.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # BEGIN reflaxe_elixir live_react_dependency
      {:live_react,
       git: "https://github.com/mrdotb/live_react.git",
       ref: "055e80e6a4e6d009df5e229eb39e7f85f03fea22"},
      # END reflaxe_elixir live_react_dependency

      # Repository example: use the exact source checkout under test.
      # Installed-package parity is verified separately by the package smoke gate.
      {:reflaxe_elixir, path: "../..", runtime: false},
      {:phoenix, "~> 1.8.9"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.2.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.5", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:daisyui,
       github: "saadeghi/daisyui",
       tag: "v5.5.20",
       sparse: "packages/bundle",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      # BEGIN reflaxe_elixir haxe_compile_client_alias
      "haxe.compile.client": [
        "haxe.watch --once --hxml build-client.hxml --dirs src_haxe --promote assets/js/_hx_app_tmp.js:assets/js/hx_app.js,assets/js/_hx_app_tmp.js.map:assets/js/hx_app.js.map"
      ],
      # END reflaxe_elixir haxe_compile_client_alias

      "haxe.compile.tests": ["cmd haxe build-tests.hxml"],
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["haxe.compile.tests", "test"],
      # BEGIN reflaxe_elixir live_react_assets_setup
      "assets.setup": [
        "tailwind.install --if-missing",
        "cmd npm install --no-audit --no-fund"
      ],
      # END reflaxe_elixir live_react_assets_setup
      # BEGIN reflaxe_elixir live_react_assets_build
      "assets.build": [

        # BEGIN reflaxe_elixir assets.build_task
        "haxe.compile.client",
        # END reflaxe_elixir assets.build_task
        "compile", "tailwind phoenixhx_live_react", "cmd npm run assets:build"],
      # END reflaxe_elixir live_react_assets_build
      "assets.deploy": [
        # BEGIN reflaxe_elixir assets.deploy_task
        "haxe.compile.client",
        # END reflaxe_elixir assets.deploy_task
        "tailwind phoenixhx_live_react --minify",
        # BEGIN reflaxe_elixir live_react_assets_deploy
        "cmd npm run assets:build",
        # END reflaxe_elixir live_react_assets_deploy
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
