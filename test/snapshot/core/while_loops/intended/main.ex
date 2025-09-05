defmodule Main do
  def main() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 3) do
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    counter = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {counter, :ok}, fn _, {acc_counter, acc_state} ->
  if (acc_counter > 0) do
    acc_counter = (acc_counter - 2)
    if (acc_counter == 4) do
      throw(:break)
    end
    {:cont, {acc_counter, acc_state}}
  else
    {:halt, {acc_counter, acc_state}}
  end
end)
    k = 0
    evens = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k < 10) do
    acc_k = acc_k + 1
    if (acc_k rem 2 != 0) do
      throw(:continue)
    end
    evens ++ [acc_k]
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count, :ok}, fn _, {acc_count, acc_state} ->
  if true do
    acc_count = acc_count + 1
    if (acc_count == 10) do
      throw(:break)
    end
    {:cont, {acc_count, acc_state}}
  else
    {:halt, {acc_count, acc_state}}
  end
end)
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {outer, inner, :ok}, fn _, {acc_outer, acc_inner, acc_state} ->
  if (acc_outer < 3) do
    acc_inner = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_inner, :ok}, fn _, {acc_inner, acc_state} ->
  if (acc_inner < 2) do
    Log.trace("Nested: " <> outer <> ", " <> acc_inner, %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "main"})
    acc_inner = acc_inner + 1
    {:cont, {acc_inner, acc_state}}
  else
    {:halt, {acc_inner, acc_state}}
  end
end)
    acc_outer = acc_outer + 1
    {:cont, {acc_outer, acc_inner, acc_state}}
  else
    {:halt, {acc_outer, acc_inner, acc_state}}
  end
end)
    a = 0
    b = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {a, b, :ok}, fn _, {acc_a, acc_b, acc_state} ->
  if (acc_a < 5 && acc_b > 5) do
    acc_a = acc_a + 1
    acc_b = (acc_b - 1)
    {:cont, {acc_a, acc_b, acc_state}}
  else
    {:halt, {acc_a, acc_b, acc_state}}
  end
end)
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, :ok}, fn _, {acc_x, acc_state} ->
  if (acc_x < 10) do
    acc_x = acc_x + 1
    if (acc_x == 5) do
      throw(:break)
    end
    {:cont, {acc_x, acc_state}}
  else
    {:halt, {acc_x, acc_state}}
  end
end)
    Log.trace("Final i: " <> i, %{:fileName => "Main.hx", :lineNumber => 68, :className => "Main", :methodName => "main"})
    Log.trace("Final j: " <> j, %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "main"})
    Log.trace("Final counter: " <> counter, %{:fileName => "Main.hx", :lineNumber => 70, :className => "Main", :methodName => "main"})
    Log.trace("Evens: " <> Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "main"})
    Log.trace("Count from infinite: " <> count, %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "main"})
    Log.trace("Complex condition result: a=" <> a <> ", b=" <> b, %{:fileName => "Main.hx", :lineNumber => 73, :className => "Main", :methodName => "main"})
    Log.trace("Do-while with break: x=" <> x, %{:fileName => "Main.hx", :lineNumber => 74, :className => "Main", :methodName => "main"})
  end
end