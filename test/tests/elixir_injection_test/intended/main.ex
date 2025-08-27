defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_elixir_injection()
  end

  @doc "Generated from Haxe testElixirInjection"
  def test_elixir_injection() do
    result = 42

    Log.trace("Result: " <> result, %{"fileName" => "Main.hx", "lineNumber" => 10, "className" => "Main", "methodName" => "testElixirInjection"})
  end

end
