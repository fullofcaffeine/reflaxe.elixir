defmodule Main do
  defp main() do
    result = IO.puts("Hello from Elixir!")
    sum = 1 + 2 + 3
    piped = [1, 2, 3] |> Enum.map(&(&1 * 2))
    multiline = 
            x = 10
            y = 20
            x + y
        
    Main.test_injection_in_function()
  end
  defp test_injection_in_function() do
    Logger.info("Injection works in functions!")
    IO.puts("Hello from function!")
  end
end