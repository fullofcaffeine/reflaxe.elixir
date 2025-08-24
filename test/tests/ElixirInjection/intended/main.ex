defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
          IO.puts("Hello from Elixir!")
          1 + 2 + 3
          [1, 2, 3] |> Enum.map(&(&1 * 2))
          
                x = 10
                y = 20
                x + y
            
          Main.test_injection_in_function()
        )
  end

  @doc "Function test_injection_in_function"
  @spec test_injection_in_function() :: nil
  def test_injection_in_function() do
    (
          Logger.info("Injection works in functions!")
          IO.puts("Hello from function!")
        )
  end

end
