defmodule Main do
  def main() do
    result = add(1, 2)
    Log.trace("Result: " <> Kernel.to_string(result), %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "main"})
    test_conditional()
    test_loop()
    test_lambda()
  end
  defp add(a, b) do
    a + b
  end
  defp test_conditional() do
    x = 10
    if (x > 5) do
      Log.trace("Greater than 5", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "testConditional"})
    else
      Log.trace("Less than or equal to 5", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "testConditional"})
    end
  end
  defp test_loop() do
    items = [1, 2, 3, 4, 5]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, items, :ok}, fn _, {acc_g, acc_items, acc_state} ->
  if (acc_g < length(acc_items)) do
    item = items[g]
    acc_g = acc_g + 1
    Log.trace("Item: " <> Kernel.to_string(item), %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "testLoop"})
    {:cont, {acc_g, acc_items, acc_state}}
  else
    {:halt, {acc_g, acc_items, acc_state}}
  end
end)
  end
  defp test_lambda() do
    numbers = [1, 2, 3]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: " <> Std.string(doubled), %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "testLambda"})
  end
end