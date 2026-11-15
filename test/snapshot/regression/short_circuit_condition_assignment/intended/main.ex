defmodule Main do
  def main() do
    m = %{"a" => -5, "b" => 4, "c" => 40}
    k = "a"
    v = and_test(m, k)
    IO.puts(v)
    v = or_test(m, k)
    IO.puts(v)
    v = middle_of_chain(m, k)
    IO.puts(v)
    v = negated_test(m, k)
    IO.puts(v)
    v = without_else(m, k)
    IO.puts(v)
    v = branch_reads(m, k)
    IO.puts(v)
    k = "b"
    v = and_test(m, k)
    IO.puts(v)
    v = or_test(m, k)
    IO.puts(v)
    v = middle_of_chain(m, k)
    IO.puts(v)
    v = negated_test(m, k)
    IO.puts(v)
    v = without_else(m, k)
    IO.puts(v)
    v = branch_reads(m, k)
    IO.puts(v)
    k = "c"
    v = and_test(m, k)
    IO.puts(v)
    v = or_test(m, k)
    IO.puts(v)
    v = middle_of_chain(m, k)
    IO.puts(v)
    v = negated_test(m, k)
    IO.puts(v)
    v = without_else(m, k)
    IO.puts(v)
    v = branch_reads(m, k)
    IO.puts(v)
    k = "x"
    v = and_test(m, k)
    IO.puts(v)
    v = or_test(m, k)
    IO.puts(v)
    v = middle_of_chain(m, k)
    IO.puts(v)
    v = negated_test(m, k)
    IO.puts(v)
    v = without_else(m, k)
    IO.puts(v)
    v = branch_reads(m, k)
    IO.puts(v)
    k = "z"
    v = and_test(m, k)
    IO.puts(v)
    v = or_test(m, k)
    IO.puts(v)
    v = middle_of_chain(m, k)
    IO.puts(v)
    v = negated_test(m, k)
    IO.puts(v)
    v = without_else(m, k)
    IO.puts(v)
    v = branch_reads(m, k)
    IO.puts(v)
  end
  defp get(m, k) do
    found = Map.get(m, k)
    if (Kernel.is_nil(found)), do: 0, else: found
  end
  def and_test(m, k) do
    v = 1
    r = "key "
    {r, v} = cond do
      k == "x" ->
        r = r <> "x"
        {r, v}
      k != "z" ->
        r = if ((v = get(m, k)) > 0), do: "pos", else: "other"
        {r, v}
      true ->
        r = "other"
        {r, v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def or_test(m, k) do
    v = 1
    r = "key "
    {r, v} = cond do
      k == "x" ->
        r = r <> "x"
        {r, v}
      k == "z" ->
        r = "zpos"
        {r, v}
      true ->
        r = if ((v = get(m, k)) > 0), do: "zpos", else: "other"
        {r, v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def middle_of_chain(m, k) do
    v = 1
    r = "size "
    {r, v} = if (k != "z") do
      r = if ((v = get(m, k)) > 0) do
        if (v < 10) do
          "#{r}small"
        else
          "other"
        end
      else
        "other"
      end
      {r, v}
    else
      r = "other"
      {r, v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def negated_test(m, k) do
    v = 1
    r = "positive "
    {r, v} = if (k != "z") do
      r = if ((v = get(m, k)) > 0) do
        "yes"
      else
        "#{r}no"
      end
      {r, v}
    else
      r = "#{r}no"
      {r, v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def without_else(m, k) do
    v = 1
    r = "none"
    {r, v} = if (k != "z") do
      r = if ((v = get(m, k)) > 0), do: "pos", else: r
      {r, v}
    else
      {r, v}
    end
    "#{r}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
  end
  def branch_reads(m, k) do
    v = 1
    if (k != "z") do
      if ((v = get(m, k)) > 0) do
        "pos#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
      else
        "other#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
      end
    else
      "other#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
    end
  end
end
