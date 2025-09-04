defmodule Main do
  defp main() do
    _result = IO.puts("Hello from Elixir!")
    _sum = 1 + 2 + 3
    _piped = [1, 2, 3] |> Enum.map(&(&1 * 2))
    _multiline = (

            x = 10
            y = 20
            x + y
        
)
    test_injection_in_function()
  end
  defp test_injection_in_function() do
    Logger.info("Injection works in functions!")
    IO.puts("Hello from function!")
  end
end