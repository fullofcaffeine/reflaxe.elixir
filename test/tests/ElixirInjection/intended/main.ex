defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    _result = IO.puts("Hello from Elixir!")

    _sum = 1 + 2 + 3

    _piped = [1, 2, 3] |> Enum.map(&(&1 * 2))

    _multiline = 
                x = 10
                y = 20
                x + y
            

    Main.test_injection_in_function()
  end

  @doc "Generated from Haxe testInjectionInFunction"
  def test_injection_in_function() do
    Logger.info("Injection works in functions!")

    IO.puts("Hello from function!")
  end

end
