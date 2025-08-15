defmodule OptionPatterns.MixProject do
  use Mix.Project

  def project do
    [
      app: :option_patterns,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Add any dependencies here
    ]
  end

  defp aliases do
    [
      # Compile Haxe source before running tests
      test: ["compile.haxe", "test"],
      "compile.haxe": &compile_haxe/1
    ]
  end

  defp compile_haxe(_) do
    case System.cmd("haxe", ["build.hxml"], stderr_to_stdout: true) do
      {output, 0} ->
        IO.puts("Haxe compilation successful")
        if String.length(output) > 0, do: IO.puts(output)

      {output, exit_code} ->
        IO.puts("Haxe compilation failed with exit code #{exit_code}")
        IO.puts(output)
        System.halt(exit_code)
    end
  end
end