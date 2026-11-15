defmodule Shadowing do
  def run() do
    r = {:ok, 3}
    v = binder_value(r)
    IO.puts(v)
    v = binder_statement(r)
    IO.puts(v)
    v = binder_two_updates(r)
    IO.puts(v)
    v = local_in_arm(r)
    IO.puts(v)
    r = {:error, "bad"}
    v = binder_value(r)
    IO.puts(v)
    v = binder_statement(r)
    IO.puts(v)
    v = binder_two_updates(r)
    IO.puts(v)
    v = local_in_arm(r)
    IO.puts(v)
    o = Main.find("payload")
    v = binder_opt(o)
    IO.puts(v)
    v = binder_other_write(o)
    IO.puts(v)
    v = push_value(o)
    IO.puts(v)
    v = push_statement(o)
    IO.puts(v)
    o = Main.find("")
    v = binder_opt(o)
    IO.puts(v)
    v = binder_other_write(o)
    IO.puts(v)
    v = push_value(o)
    IO.puts(v)
    v = push_statement(o)
    IO.puts(v)
    c = true
    v = local_value(c)
    IO.puts(v)
    v = local_statement(c)
    IO.puts(v)
    v = write_then_local(c)
    IO.puts(v)
    v = loop_value(c, [1, 2, 3])
    IO.puts(v)
    v = loop_statement(c, [1, 2, 3])
    IO.puts(v)
    c = false
    v = local_value(c)
    IO.puts(v)
    v = local_statement(c)
    IO.puts(v)
    v = write_then_local(c)
    IO.puts(v)
    v = loop_value(c, [1, 2, 3])
    IO.puts(v)
    v = loop_statement(c, [1, 2, 3])
    IO.puts(v)
  end
  defp id(n) do
    n
  end
  defp fresh() do
    ["local", "z"]
  end
  def binder_value(r) do
    value = 100
    reflaxe_outer_value_1 = value
    {ok, value} = (case r do
      {:ok, value} -> {value > 0, reflaxe_outer_value_1}
      {:error, _} ->
        value = value + 1
        {false, value}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(ok)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def binder_statement(r) do
    value = 100
    ok = false
    reflaxe_outer_value_2 = value
    {ok, value} = (case r do
      {:ok, value} ->
        ok = value > 0
        {ok, reflaxe_outer_value_2}
      {:error, _} ->
        value = value + 1
        {ok, value}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(ok)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def binder_two_updates(r) do
    value = 100
    reason = "outer"
    reflaxe_outer_value_3 = value
    {code, reason, value} = (case r do
      {:ok, value} -> {value + 1, reason, reflaxe_outer_value_3}
      {:error, e} ->
        reason = e
        value = 0
        {-1, reason, value}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(code)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}/#{reason}"
  end
  def local_in_arm(r) do
    count = 10
    {label, count} = (case r do
      {:ok, value} ->
        v = value
        reflaxe_outer_count_4 = count
        count = id(v) * 2
        {"ok#{Reflaxe.Elixir.HaxeFloat.to_string(count)}", reflaxe_outer_count_4}
      {:error, reason} ->
        e = reason
        count = count + StringTools.haxe_length(e)
        {"err", count}
    end)
    "#{label}/#{Reflaxe.Elixir.HaxeFloat.to_string(count)}"
  end
  def binder_opt(o) do
    out = "d"
    reflaxe_outer_out_5 = out
    {r, out} = (case o do
      {:some, out} -> {StringTools.haxe_length(out), reflaxe_outer_out_5}
      {:none} ->
        out = "none"
        {0, out}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{out}"
  end
  def binder_other_write(o) do
    v = "outer"
    n = 1
    reflaxe_outer_v_6 = v
    {r, n, v} = (case o do
      {:some, v} ->
        n = n + StringTools.haxe_length(v)
        {"#{v}!", n, reflaxe_outer_v_6}
      {:none} ->
        n = -n
        v = "none"
        {v, n, v}
    end)
    "#{r}/#{v}/#{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
  end
  def push_value(o) do
    items = ["a"]
    {r, items} = (case o do
      {:some, v} ->
        items = items ++ [v]
        {1, items}
      {:none} ->
        reflaxe_outer_items_7 = items
        items = fresh()
        {length(items) + 10, reflaxe_outer_items_7}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Enum.join(items, ",")}"
  end
  def push_statement(o) do
    items = ["a"]
    r = 1
    {items, r} = (case o do
      {:some, v} ->
        items = items ++ [v]
        r = r + 1
        {items, r}
      {:none} ->
        reflaxe_outer_items_8 = items
        items = fresh()
        r = r + length(items) + 10
        {reflaxe_outer_items_8, r}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Enum.join(items, ",")}"
  end
  def local_value(c) do
    v = 1
    {r, v} = if (c) do
      reflaxe_outer_v_9 = v
      v = id(5)
      {v + 1, reflaxe_outer_v_9}
    else
      v = v + 1
      {0, v}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def local_statement(c) do
    v = 1
    r = 0
    {r, v} = if (c) do
      reflaxe_outer_v_10 = v
      v = id(5)
      r = v + 1
      {r, reflaxe_outer_v_10}
    else
      v = v + 1
      {r, v}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def write_then_local(c) do
    v = 1
    {r, v} = if (c) do
      v = v + 1
      reflaxe_outer_v_11 = v
      v = id(5)
      {v + 1, reflaxe_outer_v_11}
    else
      {0, v}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def loop_value(c, xs) do
    sum = 100
    {r, sum} = if (c) do
      sum = Enum.reduce(xs, sum, fn x, sum_acc -> sum_acc + x end)
      {"loop", sum}
    else
      reflaxe_outer_sum_12 = sum
      sum = id(7)
      {"local#{Reflaxe.Elixir.HaxeFloat.to_string(sum)}", reflaxe_outer_sum_12}
    end
    "#{r}/#{Reflaxe.Elixir.HaxeFloat.to_string(sum)}"
  end
  def loop_statement(c, xs) do
    sum = 100
    r = "r"
    {r, sum} = if (c) do
      sum = Enum.reduce(xs, sum, fn x, sum_acc -> sum_acc + x end)
      r = "#{r}loop"
      {r, sum}
    else
      reflaxe_outer_sum_13 = sum
      sum = id(7)
      r = "#{r}local#{Reflaxe.Elixir.HaxeFloat.to_string(sum)}"
      {r, reflaxe_outer_sum_13}
    end
    "#{r}/#{Reflaxe.Elixir.HaxeFloat.to_string(sum)}"
  end
end
