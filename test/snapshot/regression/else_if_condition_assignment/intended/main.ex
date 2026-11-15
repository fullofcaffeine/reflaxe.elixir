defmodule Main do
  def main() do
    m = %{"a" => -5, "b" => 4}
    v = cond_assign(m, "a")
    IO.puts(v)
    v = cond_assign(m, "b")
    IO.puts(v)
    v = cond_assign(m, "x")
    IO.puts(v)
    v = cond_assign_after(m, "a")
    IO.puts(v)
    v = cond_assign_after(m, "b")
    IO.puts(v)
    v = cond_assign_after(m, "x")
    IO.puts(v)
  end
  def cond_assign(m, k) do
    _v = 0
    v = cond do
      k == "x" ->
        v = 100
        v
      true ->
        v = if ((v = Map.get(m, k)) > 0), do: v * 2, else: (v - 1)
        v
    end
    v
  end
  def cond_assign_after(m, k) do
    v = 0
    label = "key "
    {label, v} = cond do
      k == "x" ->
        label = label <> "x"
        {label, v}
      true ->
        label = if ((v = Map.get(m, k)) > 0), do: "positive", else: "other"
        {label, v}
    end
    "#{label}:#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
end
