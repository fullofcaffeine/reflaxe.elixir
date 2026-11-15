defmodule Main do
  def main() do
    m = %{"a" => "apple", "z" => "zzz"}
    k = "a"
    v = nil_then_assigned(m, k)
    IO.puts(v)
    v = set_then_assigned(m, k)
    IO.puts(v)
    v = same_condition(m, k)
    IO.puts(v)
    v = else_branch(m, k)
    IO.puts(v)
    v = value_if(m, k)
    IO.puts(v)
    v = inner_if(m, k)
    IO.puts(v)
    v = still_folded(k)
    IO.puts(v)
    k = "q"
    v = nil_then_assigned(m, k)
    IO.puts(v)
    v = set_then_assigned(m, k)
    IO.puts(v)
    v = same_condition(m, k)
    IO.puts(v)
    v = else_branch(m, k)
    IO.puts(v)
    v = value_if(m, k)
    IO.puts(v)
    v = inner_if(m, k)
    IO.puts(v)
    v = still_folded(k)
    IO.puts(v)
    k = "z"
    v = nil_then_assigned(m, k)
    IO.puts(v)
    v = set_then_assigned(m, k)
    IO.puts(v)
    v = same_condition(m, k)
    IO.puts(v)
    v = else_branch(m, k)
    IO.puts(v)
    v = value_if(m, k)
    IO.puts(v)
    v = inner_if(m, k)
    IO.puts(v)
    v = still_folded(k)
    IO.puts(v)
  end
  def nil_then_assigned(m, k) do
    if ((v = Map.get(m, k)) != "zzz") do
      if (Kernel.is_nil(v)), do: "nil", else: v
    else
      "zzz"
    end
  end
  def set_then_assigned(m, k) do
    if ((v = Map.get(m, k)) != "zzz") do
      if (Kernel.is_nil(v)), do: "nil", else: v
    else
      "zzz"
    end
  end
  def same_condition(m, k) do
    if ((v = Map.get(m, k)) != "zzz" and Kernel.is_nil(v)), do: "nil", else: "other"
  end
  def else_branch(m, k) do
    if ((v = Map.get(m, k)) == "zzz") do
      "zzz"
    else
      if (Kernel.is_nil(v)), do: "nil", else: v
    end
  end
  def value_if(m, k) do
    if ((v = Map.get(m, k)) != "zzz"), do: v || "nil", else: "zzz"
  end
  def inner_if(m, k) do
    if (k != "") do
      if ((v = Map.get(m, k)) != "zzz") do
        if (Kernel.is_nil(v)), do: "nil", else: v
      else
        "zzz"
      end
    else
      "zzz"
    end
  end
  def still_folded(k) do
    mode = "asc"
    "#{Reflaxe.Elixir.HaxeFloat.to_string(mode)}#{k}"
  end
end
