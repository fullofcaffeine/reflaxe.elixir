defmodule EctoMigrationsExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_migrations_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:haxe] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
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
      extra_applications: [:logger, :ecto_sql]
    ]
  end

  defp deps do
    [
      {:reflaxe_elixir, path: "../..", runtime: false},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
