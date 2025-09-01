defmodule Main do
  defp main() do
    result = Main.add(1, 2)
    Log.trace("Result: " + result, %{:fileName => "Main.hx", :lineNumber => 11, :className => "Main", :methodName => "main"})
    Main.test_conditional()
    Main.test_loop()
    Main.test_lambda()
  end
  defp add(a, b) do
    a + b
  end
  defp test_conditional() do
    x = 10
    if (x > 5) do
      Log.trace("Greater than 5", %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "testConditional"})
    else
      Log.trace("Less than or equal to 5", %{:fileName => "Main.hx", :lineNumber => 29, :className => "Main", :methodName => "testConditional"})
    end
  end
  defp test_loop() do
    items = [1, 2, 3, 4, 5]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < items.length) do
  item = items[g]
  g + 1
  Log.trace("Item: " + item, %{:fileName => "Main.hx", :lineNumber => 36, :className => "Main", :methodName => "testLoop"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  defp test_lambda() do
    numbers = [1, 2, 3]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: " + Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 45, :className => "Main", :methodName => "testLambda"})
  end
end