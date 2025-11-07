defmodule Main do
  def main() do
    message = "Testing composition architecture"
    _ = Log.trace(message, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    IO.puts("Injection still works")
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    if (length(doubled) > 0) do
      Enum.each(doubled, (fn -> fn item ->
                Log.trace("Doubled: " <> Kernel.to_string(item), %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "main"})
      end end).())
    end
  end
end
