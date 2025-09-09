defmodule Main do
  def main() do
    message = "Testing composition architecture"
    Log.trace(message, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    IO.puts("Injection still works")
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    if (length(doubled) > 0) do
      g = 0
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, doubled, :ok}, fn _, {acc_g, acc_doubled, acc_state} ->
  if (acc_g < length(acc_doubled)) do
    n = doubled[g]
    acc_g = acc_g + 1
    Log.trace("Doubled: " <> Kernel.to_string(n), %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "main"})
    {:cont, {acc_g, acc_doubled, acc_state}}
  else
    {:halt, {acc_g, acc_doubled, acc_state}}
  end
end)
    end
  end
end