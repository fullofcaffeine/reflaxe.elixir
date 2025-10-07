defmodule Main do
  def main() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, fn _, {i} ->
  if i < 5 do
    i + 1
    {:cont, {i}}
  else
    {:halt, {i}}
  end
end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j}, fn _, {j} ->
  if j < 3 do
    j + 1
    {:cont, {j}}
  else
    {:halt, {j}}
  end
end)
    counter = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {counter}, fn _, {counter} ->
  if counter > 0 do
    counter = (counter - 2)
    if counter == 4 do
      throw(:break)
    end
    {:cont, {counter}}
  else
    {:halt, {counter}}
  end
end)
    k = 0
    evens = []
    Enum.each(0..(10 - 1), fn k ->
  k + 1
  if rem(k, 2) != 0 do
    throw(:continue)
  end
  evens.push(k)
end)
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if true do
    count + 1
    if count == 10 do
      throw(:break)
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    outer = 0
    Enum.each(0..(3 - 1), fn outer ->
  inner = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {inner}, fn _, {inner} ->
  if inner < 2 do
    Log.trace("Nested: " <> outer.to_string() <> ", " <> inner.to_string(), %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "main"})
    inner + 1
    {:cont, {inner}}
  else
    {:halt, {inner}}
  end
end)
  outer + 1
end)
    a = 0
    b = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {a, b}, fn _, {a, b} ->
  if a < 5 and b > 5 do
    a + 1
    (b - 1)
    {:cont, {a, b}}
  else
    {:halt, {a, b}}
  end
end)
    x = 0
    Enum.each(0..(10 - 1), fn x ->
  x + 1
  if x == 5 do
    throw(:break)
  end
end)
    Log.trace("Final i: #{i}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "main"})
    Log.trace("Final j: #{j}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "main"})
    Log.trace("Final counter: #{counter}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "main"})
    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "main"})
    Log.trace("Count from infinite: #{count}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    Log.trace("Complex condition result: a=#{a}, b=#{b}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "main"})
    Log.trace("Do-while with break: x=#{x}", %{:file_name => "Main.hx", :line_number => 74, :class_name => "Main", :method_name => "main"})
  end
end