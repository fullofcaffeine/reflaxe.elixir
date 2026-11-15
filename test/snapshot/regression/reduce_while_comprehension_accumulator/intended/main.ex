defmodule Main do
  def main() do
    xs = [1, 2]
    m = %{"a" => 1, "b" => 2}
    im = %{1 => "one", 2 => "two"}
    empty = %{}
    empty_ints = %{}
    v = "keysOnly #{keys_only(m)}"
    IO.puts(v)
    v = "keysNamed #{keys_named(m)}"
    IO.puts(v)
    v = "keysOuter #{keys_outer(m, xs)}"
    IO.puts(v)
    v = "keysInner #{keys_inner(xs, m)}"
    IO.puts(v)
    v = "keysInKeys #{keys_in_keys(m, im)}"
    IO.puts(v)
    v = "valuesOuter #{values_outer(m, xs)}"
    IO.puts(v)
    v = "iteratorOuter #{iterator_outer(xs)}"
    IO.puts(v)
    v = "rangeOuter #{range_outer(im)}"
    IO.puts(v)
    v = "keysFilter #{keys_filter(m, [1, 2, 3])}"
    IO.puts(v)
    v = "emptyOuter #{keys_outer(empty, xs)}"
    IO.puts(v)
    v = "emptyInner #{keys_in_keys(m, empty_ints)}"
    IO.puts(v)
    v = "emptyRange #{range_outer(empty_ints)}"
    IO.puts(v)
  end
  def keys_only(m) do
    sorted(
      (fn ->
         {g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} ->
           try do
             acc__g = acc__g ++ [k]
             {:cont, {acc__g}}
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).()
    )
  end
  def keys_named(m) do
    {g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} ->
      try do
        acc__g = acc__g ++ [k]
        {:cont, {acc__g}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc__g}}
        :throw, :continue ->
          {:cont, {acc__g}}
      end
    end)
    items = g
    sorted(items)
  end
  def keys_outer(m, xs) do
    sorted(
      (fn ->
         {g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} ->
           try do
             acc__g = Enum.reduce(xs, acc__g, fn x, g_acc -> Enum.concat(g_acc, [k <> Reflaxe.Elixir.HaxeFloat.to_string(x)]) end)
             {:cont, {acc__g}}
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).()
    )
  end
  def keys_inner(xs, m) do
    sorted(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc ->
           {g_acc} = Enum.reduce_while(Map.keys(m), {g_acc}, fn k, {acc__g_acc} ->
             try do
               acc__g_acc = acc__g_acc ++ [k <> Reflaxe.Elixir.HaxeFloat.to_string(x)]
               {:cont, {acc__g_acc}}
             catch
               :throw, {:break, break_state} ->
                 {:halt, break_state}
               :throw, {:continue, continue_state} ->
                 {:cont, continue_state}
               :throw, :break ->
                 {:halt, {acc__g_acc}}
               :throw, :continue ->
                 {:cont, {acc__g_acc}}
             end
           end)
           g_acc
         end)
       end).()
    )
  end
  def keys_in_keys(m, im) do
    sorted(
      (fn ->
         {g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} ->
           try do
             {acc__g} = Enum.reduce_while(Map.keys(im), {acc__g}, fn j, {acc__g} ->
               try do
                 acc__g = acc__g ++ [k <> Reflaxe.Elixir.HaxeFloat.to_string(j)]
                 {:cont, {acc__g}}
               catch
                 :throw, {:break, break_state} ->
                   {:halt, break_state}
                 :throw, {:continue, continue_state} ->
                   {:cont, continue_state}
                 :throw, :break ->
                   {:halt, {acc__g}}
                 :throw, :continue ->
                   {:cont, {acc__g}}
               end
             end)
             {:cont, {acc__g}}
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).()
    )
  end
  def values_outer(m, xs) do
    sorted(
      (fn ->
         v = Reflaxe.Elixir.IMap.value_iterator(m)
         {g} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[]}, fn _, {acc__g} ->
           try do
             if ((case v do
             reflaxe_structural_receiver_node_12 ->
               (case Map.fetch(reflaxe_structural_receiver_node_12, :has_next) do
                 {:ok, reflaxe_structural_callback_node_12} ->
                   reflaxe_structural_callback_node_12.()
                 :error ->
                   apply(Map.get(reflaxe_structural_receiver_node_12, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_12, :__struct__), :has_next, [reflaxe_structural_receiver_node_12])
               end)
           end)) do
               v = (case v do
                 reflaxe_structural_receiver_node_13 ->
                   (case Map.fetch(reflaxe_structural_receiver_node_13, :next) do
                     {:ok, reflaxe_structural_callback_node_13} ->
                       reflaxe_structural_callback_node_13.()
                     :error ->
                       apply(Map.get(reflaxe_structural_receiver_node_13, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_13, :__struct__), :next, [reflaxe_structural_receiver_node_13])
                   end)
               end)
               acc__g = Enum.reduce(xs, acc__g, fn x, g_acc -> Enum.concat(g_acc, [Reflaxe.Elixir.HaxeFloat.to_string(v * 10 + x)]) end)
               {:cont, {acc__g}}
             else
               {:halt, {acc__g}}
             end
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).()
    )
  end
  def iterator_outer(xs) do
    Enum.join(
      (fn ->
         y = ArrayIterator.new(xs)
         {g} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[]}, fn _, {acc__g} ->
           try do
             if (apply(Map.get(y, :__reflaxe_class__) || Map.get(y, :__struct__), :has_next, [y])) do
               y = apply(Map.get(y, :__reflaxe_class__) || Map.get(y, :__struct__), :next, [y])
               acc__g = Enum.reduce(xs, acc__g, fn x, g_acc -> Enum.concat(g_acc, [x * 10 + y]) end)
               {:cont, {acc__g}}
             else
               {:halt, {acc__g}}
             end
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).(),
      ","
    )
  end
  def range_outer(im) do
    sorted(
      (fn ->
         {g} = Enum.reduce_while(Map.keys(im), {[]}, fn k, {acc__g} ->
           try do
             acc__g = acc__g ++ [Reflaxe.Elixir.HaxeFloat.to_string(k)]
             {:cont, {acc__g}}
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         {g} = Enum.reduce_while(Map.keys(im), {g}, fn k, {acc__g} ->
           try do
             acc__g = acc__g ++ [Reflaxe.Elixir.HaxeFloat.to_string(10 + k)]
             {:cont, {acc__g}}
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).()
    )
  end
  def keys_filter(m, xs) do
    sorted(
      (fn ->
         {g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} ->
           try do
             acc__g = if (Map.get(m, k) > 1) do
               Enum.reduce(xs, acc__g, fn x, g_acc ->
                 if (x != Map.get(m, k)) do
                   Enum.concat(g_acc, [k <> Reflaxe.Elixir.HaxeFloat.to_string(x)])
                 else
                   g_acc
                 end
               end)
             else
               acc__g
             end
             {:cont, {acc__g}}
           catch
             :throw, {:break, break_state} ->
               {:halt, break_state}
             :throw, {:continue, continue_state} ->
               {:cont, continue_state}
             :throw, :break ->
               {:halt, {acc__g}}
             :throw, :continue ->
               {:cont, {acc__g}}
           end
         end)
         g
       end).()
    )
  end
  defp sorted(items) do
    items = Enum.sort(items, fn a, b ->
      (fn a, b ->
        if (a < b) do
          -1
        else
          if (a > b), do: 1, else: 0
        end
      end).(a, b) < 0
    end)
    Enum.join(items, ",")
  end
end
