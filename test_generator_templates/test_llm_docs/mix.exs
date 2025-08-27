defmodule MixProjectExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_project_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      
      # Add Haxe compilation to the build pipeline
      compilers: [:haxe] ++ Mix.compilers(),
      
      # Configure Haxe compiler settings
      haxe_compiler: [
        hxml_file: "build.hxml",
        source_dir: "src_haxe", 
        target_dir: "lib",
        verbose: Mix.env() == :dev
      ],
      
      deps: deps(),
      
      # Test configuration
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      
      # Documentation
      name: "Mix Project Example",
      docs: [
        main: "MixProjectExample",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MixProjectExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Development and testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      
      # Optional: Add your own dependencies here
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end