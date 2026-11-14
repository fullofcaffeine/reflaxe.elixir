defmodule Main do
  def collect(count) do
    items = []
    i = 0
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = [acc_i | acc_items]
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {Enum.reverse(acc_items), acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_items), acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items
  end
  def collect_odd(count) do
    items = []
    i = 0
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i >= count) do
          throw({:break, {Enum.reverse(acc_items), acc_i}})
        end
        acc_i = acc_i + 1
        if (rem(acc_i, 2) == 0) do
          throw({:continue, {acc_items, acc_i}})
        end
        acc_items = [acc_i | acc_items]
        {:cont, {acc_items, acc_i}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_items), acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items
  end
  def until_limit(count, limit) do
    items = []
    i = 0
    (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {items, i}}, fn _, {:__reflaxe_continue__, {acc_items, acc_i}} ->
      try do
        if (acc_i > limit) do
          {:halt, {:__reflaxe_return__, "over:" <> Reflaxe.Elixir.HaxeFloat.to_string(acc_i)}}
        else
          acc_items = [acc_i * 3 | acc_items]
          acc_i = acc_i + 1
          if (acc_i == count), do: {:halt, {:__reflaxe_return__, "done:" <> Reflaxe.Elixir.HaxeFloat.to_string(length(Enum.reverse(acc_items))) <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(Enum.reverse(acc_items), (length(Enum.reverse(acc_items)) - 1)))}}, else: {:cont, {:__reflaxe_continue__, {acc_items, acc_i}}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, {:__reflaxe_continue__, break_state}}
        :throw, {:continue, continue_state} ->
          {:cont, {:__reflaxe_continue__, continue_state}}
        :throw, :break ->
          {:halt, {:__reflaxe_continue__, {Enum.reverse(acc_items), acc_i}}}
        :throw, :continue ->
          {:cont, {:__reflaxe_continue__, {acc_items, acc_i}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {reflaxe_continue_items, reflaxe_continue_i}} ->
        {_items, _i} = {reflaxe_continue_items, reflaxe_continue_i}
        nil
    end)
  end
  def squares(count) do
    _g = 0
    g_value = count
    items = Enum.map(0..(g_value - 1)//1, fn i -> i * i end)
    items
  end
  def keep_even(source) do
    kept = []
    kept = Enum.reverse(Enum.reduce(source, kept, fn value, kept_acc ->
      if (rem(value, 2) == 0) do
        kept_acc = [value | kept_acc]
        kept_acc
      else
        kept_acc
      end
    end))
    kept
  end
  def split(count) do
    low = []
    high = []
    i = 0
    {low, high, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {low, high, i}, fn _, {acc_low, acc_high, acc_i} ->
      try do
        if (acc_i < count) do
          {acc_high, acc_low} = if (Reflaxe.Elixir.HaxeFloat.lt(acc_i, Reflaxe.Elixir.HaxeFloat.divide(count, 2))) do
            acc_low = [acc_i | acc_low]
            {acc_high, acc_low}
          else
            acc_high = [acc_i | acc_high]
            {acc_high, acc_low}
          end
          acc_i = acc_i + 1
          {:cont, {acc_low, acc_high, acc_i}}
        else
          {:halt, {Enum.reverse(acc_low), Enum.reverse(acc_high), acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_low), Enum.reverse(acc_high), acc_i}}
        :throw, :continue ->
          {:cont, {acc_low, acc_high, acc_i}}
      end
    end)
    "#{Enum.join(low, ",")}|#{Enum.join(high, ",")}"
  end
  def running_total(count) do
    items = []
    total = 0
    i = 0
    {_items, total, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, total, i}, fn _, {acc_items, acc_total, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = acc_items ++ [acc_i]
          acc_total = acc_total + length(acc_items) + Enum.at(acc_items, (length(acc_items) - 1))
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_total, acc_i}}
        else
          {:halt, {acc_items, acc_total, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_items, acc_total, acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_total, acc_i}}
      end
    end)
    total
  end
  def extend(count) do
    items = [100, 200]
    i = 0
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = acc_items ++ [acc_i]
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {acc_items, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_items, acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items
  end
  def two_loops(count) do
    items = []
    i = 0
    {items, i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = [acc_i | acc_items]
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {Enum.reverse(acc_items), acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_items), acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items = items ++ [-1]
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i > 0) do
          acc_i = (acc_i - 1)
          acc_items = acc_items ++ [acc_i]
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {acc_items, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_items, acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items
  end
  def grid(rows, columns) do
    all = []
    lines = []
    row = 0
    {all, lines, _row} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {all, lines, row}, fn _, {acc_all, acc_lines, acc_row} ->
      try do
        if (acc_row < rows) do
          cells = []
          column = 0
          {acc_all, cells, _column} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_all, cells, column}, fn _, {acc_all, acc_cells, acc_column} ->
            try do
              if (acc_column < columns) do
                acc_cells = [acc_row * columns + acc_column | acc_cells]
                acc_all = acc_all ++ [acc_column]
                acc_column = acc_column + 1
                {:cont, {acc_all, acc_cells, acc_column}}
              else
                {:halt, {acc_all, Enum.reverse(acc_cells), acc_column}}
              end
            catch
              :throw, {:break, break_state} ->
                {:halt, break_state}
              :throw, {:continue, continue_state} ->
                {:cont, continue_state}
              :throw, :break ->
                {:halt, {acc_all, Enum.reverse(acc_cells), acc_column}}
              :throw, :continue ->
                {:cont, {acc_all, acc_cells, acc_column}}
            end
          end)
          acc_lines = [Enum.join(cells, " ") | acc_lines]
          acc_row = acc_row + 1
          {:cont, {acc_all, acc_lines, acc_row}}
        else
          {:halt, {acc_all, Enum.reverse(acc_lines), acc_row}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_all, Enum.reverse(acc_lines), acc_row}}
        :throw, :continue ->
          {:cont, {acc_all, acc_lines, acc_row}}
      end
    end)
    "#{Enum.join(lines, "/")}|#{Enum.join(all, "")}"
  end
  def fill(target, count) do
    i = 0
    {target, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {target, i}, fn _, {acc_target, acc_i} ->
      try do
        if (acc_i < count) do
          acc_target = acc_target ++ [acc_i]
          acc_i = acc_i + 1
          {:cont, {acc_target, acc_i}}
        else
          {:halt, {acc_target, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_target, acc_i}}
        :throw, :continue ->
          {:cont, {acc_target, acc_i}}
      end
    end)
    target
  end
  def alias_after(count) do
    items = []
    i = 0
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = [acc_i | acc_items]
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {Enum.reverse(acc_items), acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_items), acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    same = items
    "#{Reflaxe.Elixir.HaxeFloat.to_string(length(same))}:#{Reflaxe.Elixir.HaxeFloat.to_string(length(items))}:#{Enum.join(same, ",")}"
  end
  def doubled(source) do
    items = []
    i = 0
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i < length(source)) do
          acc_items = [Enum.at(source, acc_i) * 2 | acc_items]
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {Enum.reverse(acc_items), acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_items), acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items
  end
  def none() do
    items = []
    i = 5
    {items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i}, fn _, {acc_items, acc_i} ->
      try do
        if (acc_i < 3) do
          acc_items = [acc_i | acc_items]
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_i}}
        else
          {:halt, {Enum.reverse(acc_items), acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {Enum.reverse(acc_items), acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_i}}
      end
    end)
    items
  end
  defp joined(values) do
    Enum.join(values, ",")
  end
  defp describe(step) do
    g = elem(step, 1)
    values = g
    Enum.join(values, ",")
  end
  defp describe_step(step) do
    (case step do
      {:cont, box} ->
        g = elem(box, 1)
        values = g
        Enum.join(values, "")
      {:plain, values} -> "plain#{Enum.join(values, "")}"
    end)
  end
  def assign_value(count) do
    items = []
    snap = []
    i = 0
    {items, snap, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, snap, i}, fn _, {acc_items, acc_snap, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = acc_items ++ [acc_i]
          acc_snap = acc_items
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_snap, acc_i}}
        else
          {:halt, {acc_items, acc_snap, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_items, acc_snap, acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_snap, acc_i}}
      end
    end)
    "#{Enum.join(snap, ",")}|#{Enum.join(items, ",")}"
  end
  def assign_argument_for(count) do
    items = []
    seen = ""
    _g = 0
    g_value = count
    {items, seen} = Enum.reduce(0..(g_value - 1)//1, {items, seen}, fn i, {items_acc, seen_acc} ->
      seen_acc = seen_acc <> joined(items_acc = items_acc ++ [i]) <> ";"
      {items_acc, seen_acc}
    end)
    "#{seen}|#{Enum.join(items, ",")}"
  end
  defp note(values) do
    v = "note #{Enum.join(values, ",")}"
    IO.puts(v)
  end
  defp note_step(step) do
    g = elem(step, 1)
    values = g
    v = "noteStep #{Enum.join(values, ",")}"
    IO.puts(v)
  end
  def assign_only_for(count) do
    items = []
    _g = 0
    g_value = count
    items = Enum.reduce(0..(g_value - 1)//1, items, fn i, items_acc ->
      note((items_acc = Enum.concat(items_acc, [i])))
      items_acc
    end)
    Enum.join(items, ",")
  end
  def cont_only_for(count) do
    items = []
    _g = 0
    g_value = count
    items = Enum.reduce(0..(g_value - 1)//1, items, fn i, items_acc ->
      items_acc = Enum.concat(items_acc, [i])
      note_step({:cont, items_acc})
      items_acc
    end)
    Enum.join(items, ",")
  end
  def assign_argument_while(count) do
    items = []
    seen = ""
    i = 0
    {items, seen, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, seen, i}, fn _, {acc_items, acc_seen, acc_i} ->
      try do
        if (acc_i < count) do
          acc_seen = acc_seen <> joined(acc_items = acc_items ++ [acc_i]) <> ";"
          acc_i = acc_i + 1
          {:cont, {acc_items, acc_seen, acc_i}}
        else
          {:halt, {acc_items, acc_seen, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_items, acc_seen, acc_i}}
        :throw, :continue ->
          {:cont, {acc_items, acc_seen, acc_i}}
      end
    end)
    "#{seen}|#{Enum.join(items, ",")}"
  end
  def cont_box(count) do
    seen = ""
    items = []
    i = 0
    {seen, _items, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {seen, items, i}, fn _, {acc_seen, acc_items, acc_i} ->
      try do
        if (acc_i < count) do
          acc_items = acc_items ++ [acc_i]
          acc_seen = acc_seen <> describe_step({:cont, {:box, acc_items}}) <> ";"
          acc_i = acc_i + 1
          {:cont, {acc_seen, acc_items, acc_i}}
        else
          {:halt, {acc_seen, acc_items, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_seen, acc_items, acc_i}}
        :throw, :continue ->
          {:cont, {acc_seen, acc_items, acc_i}}
      end
    end)
    seen
  end
  def cont_argument(count) do
    items = []
    seen = ""
    _g = 0
    g_value = count
    {items, seen} = Enum.reduce(0..(g_value - 1)//1, {items, seen}, fn i, {items_acc, seen_acc} ->
      items_acc = items_acc ++ [i]
      seen_acc = seen_acc <> describe({:cont, items_acc}) <> ";"
      {items_acc, seen_acc}
    end)
    "#{seen}|#{Enum.join(items, ",")}"
  end
  defp line(label, result) do
    IO.puts(label <> " " <> result)
  end
  def main() do
    line("collect", Enum.join(collect(5), ","))
    line("collectOdd", Enum.join(collect_odd(9), ","))
    line("untilLimit-done", until_limit(4, 10))
    line("untilLimit-over", until_limit(40, 2))
    line("squares", Enum.join(squares(5), ","))
    line("keepEven", Enum.join(keep_even([4, 7, 10, 3, 8]), ","))
    line("split", split(6))
    line("runningTotal", "#{Reflaxe.Elixir.HaxeFloat.to_string(running_total(6))}")
    line("extend", Enum.join(extend(3), ","))
    line("twoLoops", Enum.join(two_loops(3), ","))
    line("grid", grid(2, 3))
    line("fill", Enum.join(fill([9, 8], 3), ","))
    line("aliasAfter", alias_after(4))
    line("doubled", Enum.join(doubled([1, 2, 3]), ","))
    line("none", "[#{Enum.join(none(), ",")}]")
    line("assignValue", assign_value(4))
    line("assignArgumentFor", assign_argument_for(4))
    line("assignArgumentWhile", assign_argument_while(4))
    line("contBox", cont_box(4))
    line("contArgument", cont_argument(3))
    line("assignOnlyFor", assign_only_for(3))
    line("contOnlyFor", cont_only_for(3))
  end
end
