defmodule Main do
  defp main() do
    test_while_loop()
    test_for_loop()
  end
  defp test_while_loop() do
    k = 10
    pos = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k > 0) do
  Log.trace("Processing at position: " <> pos, %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "testWhileLoop"})
  pos = pos + 1
  k = (k - 1)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Final: k=" <> k <> ", pos=" <> pos, %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "testWhileLoop"})
  end
  defp test_for_loop() do
    count = 0
    Log.trace("Iteration: " <> 0, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> 1, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> 2, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> 3, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> 4, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testForLoop"})
    count = count + 1
    Log.trace("Total count: " <> count, %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "testForLoop"})
  end
  defp test_complex_loop() do
    data = [1, 2, 3, 4, 5]
    sum = 0
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < data.length) do
  sum = sum + data[i]
  i = i + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Sum: " <> sum, %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "testComplexLoop"})
  end
end