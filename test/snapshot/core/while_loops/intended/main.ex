defmodule Main do
  def main() do
    i = 0
    Enum.each(i, fn item -> item + 1 end)
    j = 0
    Enum.each(j, fn item -> item + 1 end)
    counter = 10
    Enum.each(counter, fn item ->
      counter = (item - 2)
      if (item == 4) do
        throw(:break)
      end
    end)
    k = 0
    Enum.reduce(0..(10 - 1), [], fn x, acc ->
      if (x == 5) do
        throw(:break)
      end
      acc
    end)
    Enum.each(0..(10 - 1), fn k ->
      k + 1
      if (rem(k, 2) != 0) do
        throw(:continue)
      end
      k = Enum.concat(k, [k])
    end)
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
      if (true) do
        count + 1
        if (count == 10) do
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
      Enum.reduce_while(Stream.iterate(0, fn n -> outer + 1 end), {inner}, fn _, {inner} ->
        if (inner < 2) do
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
      if (a < 5 and b > 5) do
        a + 1
        (b - 1)
        {:cont, {a, b}}
      else
        {:halt, {a, b}}
      end
    end)
    _ = 0
    Log.trace("Final i: #{(fn -> i end).()}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "main"})
    Log.trace("Final j: #{(fn -> j end).()}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "main"})
    Log.trace("Final counter: #{(fn -> counter end).()}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "main"})
    Log.trace("Evens: #{(fn -> inspect(evens) end).()}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "main"})
    Log.trace("Count from infinite: #{(fn -> count end).()}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    Log.trace("Complex condition result: a=#{(fn -> a end).()}, b=#{(fn -> b end).()}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "main"})
  end
end
