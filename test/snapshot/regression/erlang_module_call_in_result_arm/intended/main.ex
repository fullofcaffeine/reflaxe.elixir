defmodule Main do
  def main() do
    r = {:ok, 5}
    v = other_arm_calls(r)
    IO.puts(v)
    v = same_arm_calls(r)
    IO.puts(v)
    v = guard_only_binder(r)
    IO.puts(v)
    v = after_switch(r)
    IO.puts(v)
    v = error_arm_calls(r)
    IO.puts(v)
    v = two_modules(r)
    IO.puts(v)
    r = {:ok, -2}
    v = other_arm_calls(r)
    IO.puts(v)
    v = same_arm_calls(r)
    IO.puts(v)
    v = guard_only_binder(r)
    IO.puts(v)
    v = after_switch(r)
    IO.puts(v)
    v = error_arm_calls(r)
    IO.puts(v)
    v = two_modules(r)
    IO.puts(v)
    r = {:error, "bad"}
    v = other_arm_calls(r)
    IO.puts(v)
    v = same_arm_calls(r)
    IO.puts(v)
    v = guard_only_binder(r)
    IO.puts(v)
    v = after_switch(r)
    IO.puts(v)
    v = error_arm_calls(r)
    IO.puts(v)
    v = two_modules(r)
    IO.puts(v)
    r = {:error, "x"}
    v = other_arm_calls(r)
    IO.puts(v)
    v = same_arm_calls(r)
    IO.puts(v)
    v = guard_only_binder(r)
    IO.puts(v)
    v = after_switch(r)
    IO.puts(v)
    v = error_arm_calls(r)
    IO.puts(v)
    v = two_modules(r)
    IO.puts(v)
  end
  defp round_trip(n) do
    :erlang.binary_to_term(:erlang.term_to_binary(n))
  end
  def other_arm_calls(r) do
    (case r do
      {:ok, value} ->
        cond do
          value >= 0 -> value
          true -> :erlang.binary_to_term(:erlang.term_to_binary(-1))
        end
      {:error, _} -> -2
    end)
  end
  def same_arm_calls(r) do
    (case r do
      {:ok, value} ->
        cond do
          value >= 0 -> :erlang.binary_to_term(:erlang.term_to_binary(value))
          true -> -1
        end
      {:error, _} -> -2
    end)
  end
  def guard_only_binder(r) do
    (case r do
      {:ok, value} ->
        cond do
          value >= 0 -> :erlang.binary_to_term(:erlang.term_to_binary(7))
          true -> -1
        end
      {:error, _} -> -2
    end)
  end
  def after_switch(r) do
    (case r do
      {:ok, value} ->
        n = if (value >= 0), do: value, else: -1
        round_trip(n) + :erlang.binary_to_term(:erlang.term_to_binary(1))
      {:error, _} -> -2
    end)
  end
  def error_arm_calls(r) do
    (case r do
      {:ok, _} -> "ok"
      {:error, reason} ->
        cond do
          StringTools.haxe_length(reason) > 2 -> :erlang.binary_to_term(:erlang.term_to_binary("long"))
          true -> "short"
        end
    end)
  end
  def two_modules(r) do
    (case r do
      {:ok, value} ->
        cond do
          value >= 0 ->
            items = :lists.reverse([1, 2, value])
            back = :erlang.binary_to_term(:erlang.term_to_binary(items))
            Enum.join(back, ",")
          true -> Enum.join(:lists.reverse([3, 4]), ",")
        end
      {:error, reason} -> reason
    end)
  end
end
