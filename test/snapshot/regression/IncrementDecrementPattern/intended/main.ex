defmodule Main do
  defp main() do
    test_while_loop()
    test_for_loop()
  end
  defp test_while_loop() do
    k = 10
    pos = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, k, :ok}, fn _, {acc_pos, acc_k, acc_state} ->
  if (acc_k > 0) do
    Log.trace("Processing at position: " <> acc_pos, %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "testWhileLoop"})
    acc_pos = acc_pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_pos, acc_k, acc_state}}
  else
    {:halt, {acc_pos, acc_k, acc_state}}
  end
end)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {data, i, sum, :ok}, fn _, {acc_data, acc_i, acc_sum, acc_state} ->
  if (acc_i < acc_data.length) do
    acc_sum = acc_sum + data[i]
    acc_i = acc_i + 1
    {:cont, {acc_data, acc_i, acc_sum, acc_state}}
  else
    {:halt, {acc_data, acc_i, acc_sum, acc_state}}
  end
end)
    Log.trace("Sum: " <> sum, %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "testComplexLoop"})
  end
end