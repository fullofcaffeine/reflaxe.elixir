defmodule PhoenixChat.MixProject do
  use Mix.Project

  def project do
    [
      compilers: [:haxe] ++ Mix.compilers(),
      haxe: [
        hxml_file: "build.hxml",
        source_dir: "src_haxe",
        target_dir: "lib/phoenix_chat_hx",
        watch: Mix.env() == :dev
      ],
      app: :phoenix_chat,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PhoenixChat.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:reflaxe_elixir, path: "../..", runtime: false},
      {:phoenix, "~> 1.7.24"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:floki, ">= 0.30.0", only: :test},
      # BEGIN phoenix_chat vite_live_react_dependency
      {:live_react,
       git: "https://github.com/mrdotb/live_react.git",
       ref: "055e80e6a4e6d009df5e229eb39e7f85f03fea22"},
      # END phoenix_chat vite_live_react_dependency
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.11.1"}
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
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["haxe.compile.tests", "test"],
      # BEGIN phoenix_chat vite_live_react_assets_setup
      "assets.setup": ["cmd npm ci --no-audit --no-fund", "tailwind.install --if-missing"],
      # END phoenix_chat vite_live_react_assets_setup
      # BEGIN phoenix_chat vite_live_react_assets_build
      "assets.build": [
        "haxe.compile.client",
        "cmd npm run typecheck",
        "cmd npm run assets:build",
        "tailwind phoenix_chat"
      ],
      # END phoenix_chat vite_live_react_assets_build
      # BEGIN phoenix_chat vite_live_react_assets_deploy
      "assets.deploy": [
        "haxe.compile.client",
        "cmd npm run typecheck",
        "cmd npm run assets:build",
        "tailwind phoenix_chat --minify",
        "phx.digest"
      ],
      # END phoenix_chat vite_live_react_assets_deploy
      "haxe.compile.tests": ["cmd haxe build-tests.hxml"]
    ]
  end
end
