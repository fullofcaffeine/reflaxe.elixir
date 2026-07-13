defmodule PortableChatDomain.MixProject do
  use Mix.Project

  def project do
    [
      app: :portable_chat_domain,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:haxe] ++ Mix.compilers(),
      aliases: aliases(),
      deps: deps(),
      haxe: [
        hxml_file: "build-elixir.hxml",
        source_dir: "src_haxe",
        target_dir: "lib",
        watch: false,
        verbose: Mix.env() == :dev
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp aliases do
    [test: ["haxe.compile.tests", "test"], "haxe.compile.tests": ["cmd haxe build-tests.hxml"]]
  end

  defp deps do
    [{:reflaxe_elixir, path: "../..", runtime: false}]
  end
end
