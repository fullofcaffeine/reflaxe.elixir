defmodule Main do
  def main() do
    i = 0
    _ = Enum.each(i, fn item -> item + 1 end)
    j = 0
    _ = Enum.each(j, fn item -> item + 1 end)
    counter = 10
    _ = Enum.each(counter, (fn -> fn item ->
  counter = (item - 2)
  if (item == 4) do
    throw(:break)
  end
end end).())
    k = 0
    evens = []
    _ = Enum.each(0..(10 - 1), (fn -> fn k ->
  k + 1
  if (rem(k, 2) != 0) do
    throw(:continue)
  end
  k = Enum.concat(k, [k])
end end).())
    count = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, (fn -> fn _, acc ->
  if (true) do
    count + 1
    if (count == 10) do
      throw(:break)
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end end).())
    outer = 0
    _ = Enum.each(0..(3 - 1), (fn -> fn outer ->
  inner = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> outer + 1 end), {inner}, (fn -> fn _, {inner} ->
    if (inner < 2) do
      Log.trace("Nested: " <> Kernel.to_string(outer) <> ", " <> Kernel.to_string(inner), %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "main"})
      inner + 1
      {:cont, {inner}}
    else
      {:halt, {inner}}
    end
  end end).())
  outer + 1
end end).())
    a = 0
    b = 10
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {a, b}, (fn -> fn _, {a, b} ->
  if (a < 5 and b > 5) do
    a + 1
    (b - 1)
    {:cont, {a, b}}
  else
    {:halt, {a, b}}
  end
end end).())
    x = 0
    _ = Enum.each(0..(10 - 1), (fn -> fn x ->
  x + 1
  if (x == 5) do
    throw(:break)
  end
end end).())
    _ = Log.trace("Final i: #{(fn -> i end).()}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Final j: #{(fn -> j end).()}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Final counter: #{(fn -> counter end).()}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Evens: #{(fn -> inspect(evens) end).()}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Count from infinite: #{(fn -> count end).()}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Complex condition result: a=#{(fn -> a end).()}, b=#{(fn -> b end).()}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Do-while with break: x=#{(fn -> x end).()}", %{:file_name => "Main.hx", :line_number => 74, :class_name => "Main", :method_name => "main"})
  end
end
