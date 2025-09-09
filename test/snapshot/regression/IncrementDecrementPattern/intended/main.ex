defmodule Main do
  def main() do
    test_while_loop()
    test_for_loop()
  end
  defp test_while_loop() do
    k = 10
    pos = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, pos, :ok}, fn _, {acc_k, acc_pos, acc_state} ->
  if (acc_k > 0) do
    Log.trace("Processing at position: " <> Kernel.to_string(acc_pos), %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "testWhileLoop"})
    acc_pos = acc_pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_k, acc_pos, acc_state}}
  else
    {:halt, {acc_k, acc_pos, acc_state}}
  end
end)
    Log.trace("Final: k=" <> Kernel.to_string(k) <> ", pos=" <> Kernel.to_string(pos), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testWhileLoop"})
  end
  defp test_for_loop() do
    count = 0
    Log.trace("Iteration: " <> Kernel.to_string(0), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> Kernel.to_string(1), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> Kernel.to_string(2), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> Kernel.to_string(3), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    Log.trace("Iteration: " <> Kernel.to_string(4), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    Log.trace("Total count: " <> Kernel.to_string(count), %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testForLoop"})
  end
  defp test_complex_loop() do
    data = [1, 2, 3, 4, 5]
    sum = 0
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, data, i, :ok}, fn _, {acc_sum, acc_data, acc_i, acc_state} -> nil end)
    Log.trace("Sum: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testComplexLoop"})
  end
end