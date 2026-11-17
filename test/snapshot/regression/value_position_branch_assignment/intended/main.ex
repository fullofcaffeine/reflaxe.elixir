defmodule Main do
  def main() do
    k = "x"
    v = switch_value(find(k))
    IO.puts(v)
    v = switch_call_subject(k)
    IO.puts(v)
    v = if_value(k)
    IO.puts(v)
    v = if_assignment(k)
    IO.puts(v)
    v = ternary_assignment_branch(k)
    IO.puts(v)
    v = nested_ternary_binding(k)
    IO.puts(v)
    v = nested_switch(find(k), k == "")
    IO.puts(v)
    v = shadowed_local(k == "x")
    IO.puts(v)
    v = throwing_branch(k == "x")
    IO.puts(v)
    v = returns_updated(k)
    IO.puts(v)
    v = returns_value_only(k)
    IO.puts(v)
    k = ""
    v = switch_value(find(k))
    IO.puts(v)
    v = switch_call_subject(k)
    IO.puts(v)
    v = if_value(k)
    IO.puts(v)
    v = if_assignment(k)
    IO.puts(v)
    v = ternary_assignment_branch(k)
    IO.puts(v)
    v = nested_ternary_binding(k)
    IO.puts(v)
    v = nested_switch(find(k), k == "")
    IO.puts(v)
    v = shadowed_local(k == "x")
    IO.puts(v)
    v = throwing_branch(k == "x")
    IO.puts(v)
    v = returns_updated(k)
    IO.puts(v)
    v = returns_value_only(k)
    IO.puts(v)
    v = nested_ternary_binding("y")
    IO.puts(v)
    v = nested_switch({:some, "q"}, true)
    IO.puts(v)
    v = allowed(["a", "order", "b"])
    IO.puts(v)
    v = allowed(["a", "b"])
    IO.puts(v)
    v = allowed([])
    IO.puts(v)
    v = last_some([{:some, "a"}, {:none}, {:some, "bcd"}])
    IO.puts(v)
    v = largest([1, 5, 2, 9, 3])
    IO.puts(v)
    v = odd_steps(5)
    IO.puts(v)
    Shadowing.run()
  end
  def find(s) do
    if (s == ""), do: {:none}, else: {:some, s}
  end
  defp score(k) do
    if (k == "x") do
      7
    else
      if (k == "y"), do: -7, else: 0
    end
  end
  def switch_value(o) do
    out = "d"
    {r, out} = (case o do
      {:some, v} ->
        out = v
        {1, out}
      {:none} -> {0, out}
    end)
    "#{out}#{Reflaxe.Elixir.HaxeFloat.to_string(r)}"
  end
  def switch_call_subject(k) do
    out = "d"
    {r, out} = (case find(k) do
      {:some, v} ->
        out = v
        {StringTools.haxe_length(v), out}
      {:none} -> {0, out}
    end)
    "#{out}#{Reflaxe.Elixir.HaxeFloat.to_string(r)}"
  end
  def if_value(k) do
    v = 1
    {r, v} = if (k == "x") do
      v = 2
      {"a", v}
    else
      {"b", v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def if_assignment(k) do
    v = 1
    r = "r"
    {r, v} = if (k == "x") do
      v = v + 1
      {"#{r}a", v}
    else
      v = v + 2
      {"#{r}b", v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def ternary_assignment_branch(k) do
    v = 1
    {r, v} = if (k == "x") do
      v = 2
      {v, v}
    else
      {0, v}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def nested_ternary_binding(k) do
    v = 1
    {r, v} = if (k == "") do
      {"empty", v}
    else
      if ((v = score(k)) > 0), do: {"pos", v}, else: {"other", v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def nested_switch(o, flag) do
    out = "d"
    hits = 0
    {r, hits, out} = (case o do
      {:some, v} ->
        {{out, reflaxe_call_value_1}, hits} = (fn ->
          out = v
          {inner, hits} = if (flag) do
            hits = hits + 10
            {"f", hits}
          else
            {"n", hits}
          end
          {size, hits} = (case find(v <> v) do
            {:some, w} ->
              hits = hits + 1
              {StringTools.haxe_length(w), hits}
            {:none} -> {0, hits}
          end)
          {{out, inner <> Reflaxe.Elixir.HaxeFloat.to_string(size)}, hits}
        end).()
        {reflaxe_call_value_1, hits, out}
      {:none} when flag ->
        hits = -1
        {"none!", hits, out}
      {:none} -> {"none", hits, out}
    end)
    "#{r}/#{out}/#{Reflaxe.Elixir.HaxeFloat.to_string(hits)}"
  end
  def shadowed_local(c) do
    v = 1
    seen = 0
    {r, seen} = if (c) do
      v_shadow = score("x")
      seen = v_shadow
      {v_shadow + 1, seen}
    else
      {0, seen}
    end
    "#{Reflaxe.Elixir.HaxeFloat.to_string(r)}/#{Reflaxe.Elixir.HaxeFloat.to_string(v)}/#{Reflaxe.Elixir.HaxeFloat.to_string(seen)}"
  end
  def throwing_branch(c) do
    out = "d"
    try do
      {r, out} = if (c) do
        out = "set"
        {1, out}
      else
        raise Reflaxe.Elixir.HaxeThrow, [value: "boom"]
      end
      out <> Reflaxe.Elixir.HaxeFloat.to_string(r)
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {e, _} when is_binary(e) -> out <> e
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def returns_updated(k) do
    out = "d"
    {hit, out} = (case find(k) do
      {:some, v} ->
        out = v
        {true, out}
      {:none} -> {false, out}
    end)
    out = if (hit) do
      "#{out}!"
    else
      out
    end
    out
  end
  def returns_value_only(k) do
    out = "d"
    (case find(k) do
      {:some, v} ->
        out = "#{v}#{out}"
        StringTools.haxe_length(out)
      {:none} -> 0
    end)
  end
  def allowed(names) do
    seen = false
    (case Enum.reduce_while(names, {:__reflaxe_continue__, seen}, fn name, {:__reflaxe_continue__, seen_acc} ->
      {ok, seen_acc} = if (name == "order") do
        seen_acc = true
        {StringTools.haxe_length(name) > 0, seen_acc}
      else
        {true, seen_acc}
      end
      if (not ok), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, {:__reflaxe_continue__, seen_acc}}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_seen} ->
        seen = reflaxe_continue_seen
        seen
    end)
  end
  def last_some(items) do
    last = "none"
    total = 0
    {last, total} = Enum.reduce(items, {last, total}, fn item, {last_acc, total_acc} ->
      {n, last_acc} = (case item do
        {:some, v} ->
          last_acc = v
          {StringTools.haxe_length(v), last_acc}
        {:none} -> {0, last_acc}
      end)
      total_acc = total_acc + n
      {last_acc, total_acc}
    end)
    "#{last}/#{Reflaxe.Elixir.HaxeFloat.to_string(total)}"
  end
  def largest(xs) do
    big = 0
    labels = ""
    {big, labels} = Enum.reduce(xs, {big, labels}, fn x, {big_acc, labels_acc} ->
      {label, big_acc} = if (x > big_acc) do
        big_acc = x
        {"B", big_acc}
      else
        {"s", big_acc}
      end
      labels_acc = labels_acc <> label
      {big_acc, labels_acc}
    end)
    "#{labels}#{Reflaxe.Elixir.HaxeFloat.to_string(big)}"
  end
  def odd_steps(n) do
    i = 0
    odd = 0
    acc = ""
    {_i, odd, acc} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, odd, acc}, fn _, {acc_i, acc_odd, acc_acc} ->
      try do
        if (acc_i < n) do
          {t, acc_odd} = if (rem(acc_i, 2) == 1) do
            acc_odd = acc_i
            {acc_odd, acc_odd}
          else
            {0, acc_odd}
          end
          acc_acc = acc_acc <> Reflaxe.Elixir.HaxeFloat.to_string(t)
          acc_i = acc_i + 1
          {:cont, {acc_i, acc_odd, acc_acc}}
        else
          {:halt, {acc_i, acc_odd, acc_acc}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_i, acc_odd, acc_acc}}
        :throw, :continue ->
          {:cont, {acc_i, acc_odd, acc_acc}}
      end
    end)
    "#{acc}/#{Reflaxe.Elixir.HaxeFloat.to_string(odd)}"
  end
end
