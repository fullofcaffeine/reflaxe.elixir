defmodule Main do
  def main() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, fn _, {acc_i} ->
      try do
        if (acc_i < 5) do
          old_i = acc_i
          acc_i = acc_i + 1
          {:cont, {acc_i}}
        else
          {:halt, {acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_i}}
        :throw, :continue ->
          {:cont, {acc_i}}
      end
    end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j}, fn _, {acc_j} ->
      try do
        if (acc_j < 3) do
          old_j = acc_j
          acc_j = acc_j + 1
          {:cont, {acc_j}}
        else
          {:halt, {acc_j}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_j}}
        :throw, :continue ->
          {:cont, {acc_j}}
      end
    end)
    counter = 10
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {counter}, fn _, {acc_counter} ->
      try do
        if (acc_counter > 0) do
          acc_counter = (acc_counter - 2)
          if (acc_counter == 4) do
            throw({:break, {acc_counter}})
          end
          {:cont, {acc_counter}}
        else
          {:halt, {acc_counter}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_counter}}
        :throw, :continue ->
          {:cont, {acc_counter}}
      end
    end)
    k = 0
    evens = []
    {_k, _evens} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, evens}, fn _, {acc_k, acc_evens} ->
      try do
        if (acc_k < 10) do
          old_k = acc_k
          acc_k = acc_k + 1
          if (rem(acc_k, 2) != 0) do
            throw({:continue, {acc_k, acc_evens}})
          end
          acc_evens = acc_evens ++ [acc_k]
          {:cont, {acc_k, acc_evens}}
        else
          {:halt, {acc_k, acc_evens}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_k, acc_evens}}
        :throw, :continue ->
          {:cont, {acc_k, acc_evens}}
      end
    end)
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count}, fn _, {acc_count} ->
      try do
        old_count = acc_count
        acc_count = acc_count + 1
        if (acc_count == 10) do
          throw({:break, {acc_count}})
        end
        {:cont, {acc_count}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_count}}
        :throw, :continue ->
          {:cont, {acc_count}}
      end
    end)
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {outer}, fn _, {acc_outer} ->
      try do
        if (acc_outer < 3) do
          inner = 0
          Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {inner}, fn _, {acc_inner} ->
            try do
              if (acc_inner < 2) do
                old_inner = acc_inner
                acc_inner = acc_inner + 1
                {:cont, {acc_inner}}
              else
                {:halt, {acc_inner}}
              end
            catch
              :throw, {:break, break_state} ->
                {:halt, break_state}
              :throw, {:continue, continue_state} ->
                {:cont, continue_state}
              :throw, :break ->
                {:halt, {acc_inner}}
              :throw, :continue ->
                {:cont, {acc_inner}}
            end
          end)
          old_outer = acc_outer
          acc_outer = acc_outer + 1
          {:cont, {acc_outer}}
        else
          {:halt, {acc_outer}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_outer}}
        :throw, :continue ->
          {:cont, {acc_outer}}
      end
    end)
    a = 0
    b = 10
    {_a, _b} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {a, b}, fn _, {acc_a, acc_b} ->
      try do
        if (acc_a < 5 and acc_b > 5) do
          old_a = acc_a
          acc_a = acc_a + 1
          old_b = acc_b
          acc_b = (acc_b - 1)
          {:cont, {acc_a, acc_b}}
        else
          {:halt, {acc_a, acc_b}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_a, acc_b}}
        :throw, :continue ->
          {:cont, {acc_a, acc_b}}
      end
    end)
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x}, fn _, {acc_x} ->
      try do
        if (acc_x < 10) do
          old_x = acc_x
          acc_x = acc_x + 1
          if (acc_x == 5) do
            throw({:break, {acc_x}})
          end
          {:cont, {acc_x}}
        else
          {:halt, {acc_x}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_x}}
        :throw, :continue ->
          {:cont, {acc_x}}
      end
    end)
    nil
  end
end
