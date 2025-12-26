defmodule Main do
  def main() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {i} ->
      if (i < 5) do
        (old_i = i
i = i + 1
old_i)
        {:cont, {i}}
      else
        {:halt, {i}}
      end
    end end).())
    nil
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {j} ->
      if (j < 3) do
        (old_j = j
j = j + 1
old_j)
        {:cont, {j}}
      else
        {:halt, {j}}
      end
    end end).())
    nil
    counter = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {counter} ->
      if (counter > 0) do
        counter = (counter - 2)
        if (counter == 4) do
          throw(:break)
        end
        {:cont, {counter}}
      else
        {:halt, {counter}}
      end
    end end).())
    nil
    k = 0
    evens = []
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, evens}, (fn -> fn _, {k, evens} ->
      if (k < 10) do
        (old_k = k
k = k + 1
old_k)
        if (rem(k, 2) != 0) do
          throw(:continue)
        end
        _ = evens ++ [k]
        {:cont, {k, evens}}
      else
        {:halt, {k, evens}}
      end
    end end).())
    nil
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {count} ->
      (old_count = count
count = count + 1
old_count)
      if (count == 10) do
        throw(:break)
      end
      {:cont, {count}}
    end end).())
    nil
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {outer} ->
      if (outer < 3) do
        inner = 0
        Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {inner} ->
          if (inner < 2) do
            (old_inner = inner
inner = inner + 1
old_inner)
            {:cont, {inner}}
          else
            {:halt, {inner}}
          end
        end end).())
        nil
        (old_outer = outer
outer = outer + 1
old_outer)
        {:cont, {outer}}
      else
        {:halt, {outer}}
      end
    end end).())
    nil
    a = 0
    b = 10
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, (fn -> fn _, {a, b} ->
      if (a < 5 and b > 5) do
        (old_a = a
a = a + 1
old_a)
        (old_b = b
b = (b - 1)
old_b)
        {:cont, {a, b}}
      else
        {:halt, {a, b}}
      end
    end end).())
    nil
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {x} ->
      if (x < 10) do
        (old_x = x
x = x + 1
old_x)
        if (x == 5) do
          throw(:break)
        end
        {:cont, {x}}
      else
        {:halt, {x}}
      end
    end end).())
    nil
    nil
  end
end
