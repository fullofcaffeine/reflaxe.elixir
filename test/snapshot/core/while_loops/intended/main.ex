defmodule Main do
  def main() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {i} ->
      if (i < 5) do
        _old_i = i
        i = i + 1
        {:cont, {i}}
      else
        {:halt, {i}}
      end
    end)
    nil
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {j} ->
      if (j < 3) do
        _old_j = j
        j = j + 1
        {:cont, {j}}
      else
        {:halt, {j}}
      end
    end)
    nil
    counter = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {counter} ->
      if (counter > 0) do
        counter = (counter - 2)
        if (counter == 4) do
          throw(:break)
        end
        {:cont, {counter}}
      else
        {:halt, {counter}}
      end
    end)
    nil
    k = 0
    evens = []
    {k, evens} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, []}, fn _, {k, evens} ->
      if (k < 10) do
        _old_k = k
        k = k + 1
        if (rem(k, 2) != 0) do
          throw(:continue)
        end
        evens = evens ++ [k]
        {:cont, {k, evens}}
      else
        {:halt, {k, evens}}
      end
    end)
    nil
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {count} ->
      _old_count = count
      count = count + 1
      if (count == 10) do
        throw(:break)
      end
      {:cont, {count}}
    end)
    nil
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {outer} ->
      if (outer < 3) do
        inner = 0
        Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {inner} ->
          if (inner < 2) do
            _old_inner = inner
            inner = inner + 1
            {:cont, {inner}}
          else
            {:halt, {inner}}
          end
        end)
        nil
        old_outer = outer
        outer = outer + 1
        old_outer
        {:cont, {outer}}
      else
        {:halt, {outer}}
      end
    end)
    nil
    a = 0
    b = 10
    {a, b} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, fn _, {a, b} ->
      if (a < 5 and b > 5) do
        _old_a = a
        a = a + 1
        old_b = b
        b = (b - 1)
        old_b
        {:cont, {a, b}}
      else
        {:halt, {a, b}}
      end
    end)
    nil
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {x} ->
      if (x < 10) do
        _old_x = x
        x = x + 1
        if (x == 5) do
          throw(:break)
        end
        {:cont, {x}}
      else
        {:halt, {x}}
      end
    end)
    nil
    nil
  end
end
