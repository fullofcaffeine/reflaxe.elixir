defmodule Main do
  def main() do
    v = nested_guard({:err, {:stale, 5, 0}})
    IO.puts(v)
    v = nested_guard({:err, {:stale, -5, 0}})
    IO.puts(v)
    v = nested_guard({:err, {:fresh, 3}})
    IO.puts(v)
    v = nested_guard({:ok, 1})
    IO.puts(v)
    v = guard_on_later_case({:err, {:fresh, 7}})
    IO.puts(v)
    v = guard_on_later_case({:err, {:fresh, -7}})
    IO.puts(v)
    v = guard_on_later_case({:err, {:stale, 1, 2}})
    IO.puts(v)
  end
  def nested_guard(r) do
    value = 100
    (case r do
      {:err, g} ->
        (case g do
          {:stale, wanted, _} -> if (wanted > 0), do: wanted + value, else: -1
          {:fresh, count} -> count + value
          _ -> -1
        end)
      _ -> -1
    end)
  end
  def guard_on_later_case(r) do
    (case r do
      {:err, g} ->
        (case g do
          {:stale, wanted, other} -> wanted * 10 + other
          {:fresh, count} -> if (count > 0), do: count, else: 0
          _ -> 0
        end)
      _ -> 0
    end)
  end
end
