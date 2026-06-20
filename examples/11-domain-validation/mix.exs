defmodule DomainValidation.MixProject do
  use Mix.Project

  def project do
    [
      app: :domain_validation,
      version: "1.0.0",
      elixir: "~> 1.14",
      compilers: [:haxe] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      haxe: [
        hxml_file: "build.hxml",
        source_dir: ".",
        target_dir: "lib",
        watch: false,
        verbose: Mix.env() == :dev
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:reflaxe_elixir, path: "../..", runtime: false}
    ]
  end
end
