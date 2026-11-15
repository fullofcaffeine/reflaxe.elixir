defmodule Main do
  def main() do
    v = "twoPlain #{two_plain(["a", "b"], ["1", "2"])}"
    IO.puts(v)
    v = "statementLoops #{statement_loops(["a", "b"], ["1", "2"])}"
    IO.puts(v)
    r = {:ok, "o"}
    v = "twoSwitch #{two_switch(r, ["a", "b"], ["1", "2"])}"
    IO.puts(v)
    v = "twoSwitchGuard #{two_switch_guard(r, ["a", "b"], ["1", "2"])}"
    IO.puts(v)
    v = "threeSwitch #{three_switch(r, ["a", "b"], ["1", "2"], ["p", "q"])}"
    IO.puts(v)
    v = "twoFilter #{two_filter(r, [1, 2, 3], [1, 2, 3])}"
    IO.puts(v)
    v = "innerRange #{inner_range(r, ["a", "b"], 3)}"
    IO.puts(v)
    v = "innerMap #{inner_map(r, ["a", "b"], %{"k" => 1, "j" => 2})}"
    IO.puts(v)
    v = "named #{Reflaxe.Elixir.HaxeFloat.to_string(named(r, ["a", "b"], ["1", "2", "3"]))}"
    IO.puts(v)
    r = {:error, "x"}
    v = "twoSwitch #{two_switch(r, ["a", "b"], ["1", "2"])}"
    IO.puts(v)
    v = "twoSwitchGuard #{two_switch_guard(r, ["a", "b"], ["1", "2"])}"
    IO.puts(v)
    v = "threeSwitch #{three_switch(r, ["a", "b"], ["1", "2"], ["p", "q"])}"
    IO.puts(v)
    v = "twoFilter #{two_filter(r, [1, 2, 3], [1, 2, 3])}"
    IO.puts(v)
    v = "innerRange #{inner_range(r, ["a", "b"], 3)}"
    IO.puts(v)
    v = "innerMap #{inner_map(r, ["a", "b"], %{"k" => 1, "j" => 2})}"
    IO.puts(v)
    v = "named #{Reflaxe.Elixir.HaxeFloat.to_string(named(r, ["a", "b"], ["1", "2", "3"]))}"
    IO.puts(v)
    v = "emptyInner #{two_plain(["a", "b"], [])}"
    IO.puts(v)
    v = "emptyOuter #{two_plain([], ["1", "2"])}"
    IO.puts(v)
  end
  def two_plain(xs, ys) do
    Enum.join(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc -> Enum.reduce(ys, g_acc, fn y, g_acc -> Enum.concat(g_acc, [x <> y]) end) end)
       end).(),
      ","
    )
  end
  def statement_loops(xs, ys) do
    out = []
    out = Enum.reduce(xs, out, fn x, out_acc -> Enum.reduce(ys, out_acc, fn y, out_acc -> Enum.concat(out_acc, [y <> x]) end) end)
    Enum.join(out, ",")
  end
  def two_switch(r, xs, ys) do
    Enum.join(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc ->
           Enum.reduce(ys, g_acc, fn y, g_acc ->
             Enum.concat(g_acc, [(case r do
               {:ok, _} -> "o"
               {:error, reason} ->
                 e = reason
                 x <> y <> e
             end)])
           end)
         end)
       end).(),
      ","
    )
  end
  def two_switch_guard(r, xs, ys) do
    Enum.join(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc ->
           Enum.reduce(ys, g_acc, fn y, g_acc ->
             Enum.concat(g_acc, [(case r do
               {:ok, _} -> "o"
               {:error, reason} ->
                 e = reason
                 if (x == "a"), do: x <> y <> e, else: "E" <> y
             end)])
           end)
         end)
       end).(),
      ","
    )
  end
  def three_switch(r, xs, ys, zs) do
    Enum.join(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc ->
           Enum.reduce(ys, g_acc, fn y, g_acc ->
             Enum.reduce(zs, g_acc, fn z, g_acc ->
               Enum.concat(g_acc, [(case r do
                 {:ok, _} -> "o"
                 {:error, reason} ->
                   e = reason
                   x <> y <> z <> e
               end)])
             end)
           end)
         end)
       end).(),
      ","
    )
  end
  def two_filter(r, xs, ys) do
    Enum.join(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc ->
           if (x > 1) do
             Enum.reduce(ys, g_acc, fn y, g_acc ->
               if (y != x) do
                 Enum.concat(g_acc, [(case r do
                   {:ok, _} -> "o"
                   {:error, reason} ->
                     e = reason
                     Reflaxe.Elixir.HaxeFloat.to_string(x) <> "" <> Reflaxe.Elixir.HaxeFloat.to_string(y) <> e
                 end)])
               else
                 g_acc
               end
             end)
           else
             g_acc
           end
         end)
       end).(),
      ","
    )
  end
  def inner_range(r, xs, n) do
    Enum.join(
      (fn ->
         g = []
         Enum.reduce(xs, g, fn x, g_acc ->
           g2 = n
           Enum.reduce(1..(g2 - 1)//1, g_acc, fn i, g_acc ->
             Enum.concat(g_acc, [(case r do
               {:ok, _} -> "o"
               {:error, reason} ->
                 e = reason
                 x <> Reflaxe.Elixir.HaxeFloat.to_string(i) <> e
             end)])
           end)
         end)
       end).(),
      ","
    )
  end
  def inner_map(r, xs, m) do
    g = []
    out = Enum.reduce(xs, g, fn x, g_acc ->
      {g_acc} = Enum.reduce_while(Map.keys(m), {g_acc}, fn k, {acc__g_acc} ->
        try do
          acc__g_acc = acc__g_acc ++ [(case r do
          {:ok, _} -> "o"
          {:error, reason} ->
            e = reason
            x <> k <> e
        end)]
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
    out = Enum.sort(out, fn a, b ->
      (fn a, b ->
        if (a < b) do
          -1
        else
          if (a > b), do: 1, else: 0
        end
      end).(a, b) < 0
    end)
    Enum.join(out, ",")
  end
  def named(r, xs, ys) do
    g = []
    items = Enum.reduce(xs, g, fn x, g_acc ->
      Enum.reduce(ys, g_acc, fn y, g_acc ->
        Enum.concat(g_acc, [(case r do
          {:ok, _} -> "o"
          {:error, reason} ->
            e = reason
            x <> y <> e
        end)])
      end)
    end)
    length(items)
  end
end
