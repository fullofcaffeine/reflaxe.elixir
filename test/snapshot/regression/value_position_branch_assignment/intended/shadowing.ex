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
    v = capture_name_taken(r)
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
    v = capture_name_taken(r)
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
    v = arm_local_inside_if(o, true)
    IO.puts(v)
    v = arm_local_inside_if(o, false)
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
    v = arm_local_inside_if(o, true)
    IO.puts(v)
    v = arm_local_inside_if(o, false)
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
    v = range_loop_local(c)
    IO.puts(v)
    v = array_loop_local(c)
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
    v = range_loop_local(c)
    IO.puts(v)
    v = array_loop_local(c)
    IO.puts(v)
  end
  def capture_name_taken(r) do
    reflaxe_outer_value_1 = 7
    reflaxe_outer_value_2 = 8
    value = 100
    reflaxe_outer_value_3 = value
    {ok, value} = (case r do
      {:ok, value} -> {value > 0, reflaxe_outer_value_3}
      {:error, _} ->
        value = value + 1
        {false, value}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(ok)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}/#{Reflaxe.Elixir.HaxeFloat.to_string(reflaxe_outer_value_1)}/#{Reflaxe.Elixir.HaxeFloat.to_string(reflaxe_outer_value_2)}"
  end
  defp id(n) do
    n
  end
  defp fresh() do
    ["local", "z"]
  end
  def binder_value(r) do
    value = 100
    reflaxe_outer_value_4 = value
    {ok, value} = (case r do
      {:ok, value} -> {value > 0, reflaxe_outer_value_4}
      {:error, _} ->
        value = value + 1
        {false, value}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(ok)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def binder_statement(r) do
    value = 100
    ok = false
    reflaxe_outer_value_5 = value
    {ok, value} = (case r do
      {:ok, value} ->
        ok = value > 0
        {ok, reflaxe_outer_value_5}
      {:error, _} ->
        value = value + 1
        {ok, value}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(ok)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def binder_two_updates(r) do
    value = 100
    reason = "outer"
    reflaxe_outer_value_6 = value
    {code, reason, value} = (case r do
      {:ok, value} -> {value + 1, reason, reflaxe_outer_value_6}
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
        count_shadow = id(v) * 2
        {"ok#{Reflaxe.Elixir.HaxeFloat.to_string(count_shadow)}", count}
      {:error, reason} ->
        e = reason
        count = count + StringTools.haxe_length(e)
        {"err", count}
    end)
    "#{label}/#{Reflaxe.Elixir.HaxeFloat.to_string(count)}"
  end
  def binder_opt(o) do
    out = "d"
    reflaxe_outer_out_7 = out
    {r, out} = (case o do
      {:some, out} -> {StringTools.haxe_length(out), reflaxe_outer_out_7}
      {:none} ->
        out = "none"
        {0, out}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{out}"
  end
  def binder_other_write(o) do
    v = "outer"
    n = 1
    reflaxe_outer_v_8 = v
    {r, n, v} = (case o do
      {:some, v} ->
        n = n + StringTools.haxe_length(v)
        {"#{v}!", n, reflaxe_outer_v_8}
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
        items_shadow = fresh()
        {length(items_shadow) + 10, items}
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
        items_shadow = fresh()
        r = r + length(items_shadow) + 10
        {items, r}
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Enum.join(items, ",")}"
  end
  def local_value(c) do
    v = 1
    {r, v} = if (c) do
      v_shadow = id(5)
      {v_shadow + 1, v}
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
      v_shadow = id(5)
      r = v_shadow + 1
      {r, v}
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
      v_shadow = id(5)
      {v_shadow + 1, v}
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
      sum_shadow = id(7)
      {"local#{Reflaxe.Elixir.HaxeFloat.to_string(sum_shadow)}", sum}
    end
    "#{r}/#{Reflaxe.Elixir.HaxeFloat.to_string(sum)}"
  end
  def range_loop_local(c) do
    v = 1
    total = 0
    {r, _total, v} = if (c) do
      v_shadow = id(0) * 2
      total = total + v_shadow
      v_shadow = id(1) * 2
      total = total + v_shadow
      v_shadow = id(2) * 2
      total = total + v_shadow
      {total, total, v}
    else
      v = v + 1
      {0, total, v}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def array_loop_local(c) do
    v = 1
    total = 0
    {r, _total, v} = if (c) do
      x = 1
      v_shadow = id(x) * 2
      total = total + v_shadow
      x = 2
      v_shadow = id(x) * 2
      total = total + v_shadow
      x = 3
      v_shadow = id(x) * 2
      total = total + v_shadow
      {total, total, v}
    else
      v = v + 1
      {0, total, v}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def arm_local_inside_if(o, c) do
    n = 0
    seen = 0
    {out, n, _seen} = if (c) do
      {n, seen} = (case o do
        {:some, x} ->
          n_shadow = StringTools.haxe_length(x)
          seen = n_shadow
          {n, seen}
        {:none} ->
          n = -1
          {n, seen}
      end)
      {seen, n, seen}
    else
      {0, n, seen}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(out)}/#{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
  end
  def loop_statement(c, xs) do
    sum = 100
    r = "r"
    {r, sum} = if (c) do
      sum = Enum.reduce(xs, sum, fn x, sum_acc -> sum_acc + x end)
      r = "#{r}loop"
      {r, sum}
    else
      sum_shadow = id(7)
      r = "#{r}local#{Reflaxe.Elixir.HaxeFloat.to_string(sum_shadow)}"
      {r, sum}
    end
    "#{r}/#{Reflaxe.Elixir.HaxeFloat.to_string(sum)}"
  end
end
