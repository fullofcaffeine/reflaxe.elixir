defmodule Main do
  def main() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < 5) do
  i + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (j < 3) do
  j + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    counter = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (counter > 0) do
  counter = counter - 2
  if (counter == 4) do
    throw(:break)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    k = 0
    evens = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k < 10) do
  k + 1
  if (k rem 2 != 0) do
    throw(:continue)
  end
  evens.push(k)
  {:cont, acc}
else
  {:halt, acc}
end end)
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if true do
  count + 1
  if (count == 10) do
    throw(:break)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (outer < 3) do
  inner = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (inner < 2) do
  Log.trace("Nested: " + outer + ", " + inner, %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "main"})
  inner + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
  outer + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    a = 0
    b = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (a < 5 && b > 5) do
  a + 1
  b - 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (x < 10) do
  x + 1
  if (x == 5) do
    throw(:break)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Final i: " + i, %{:fileName => "Main.hx", :lineNumber => 68, :className => "Main", :methodName => "main"})
    Log.trace("Final j: " + j, %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "main"})
    Log.trace("Final counter: " + counter, %{:fileName => "Main.hx", :lineNumber => 70, :className => "Main", :methodName => "main"})
    Log.trace("Evens: " + Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "main"})
    Log.trace("Count from infinite: " + count, %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "main"})
    Log.trace("Complex condition result: a=" + a + ", b=" + b, %{:fileName => "Main.hx", :lineNumber => 73, :className => "Main", :methodName => "main"})
    Log.trace("Do-while with break: x=" + x, %{:fileName => "Main.hx", :lineNumber => 74, :className => "Main", :methodName => "main"})
  end
end