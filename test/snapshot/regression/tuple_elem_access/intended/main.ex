defmodule Main do
  def main() do
    one_based = one_based_tuple()
    if (elem(one_based, 0) != "one" or elem(one_based, 1) != 2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "one-based tuple access failed"]
    end
    matched = if (elem(one_based, 0) == "one") do
      value = elem(one_based, 1)
      value
    else
      -1
    end
    if (matched != 2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "one-based tuple pattern failed"]
    end
    zero_based = zero_based_tuple()
    if (elem(zero_based, 0) != "zero" or elem(zero_based, 1) != 1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "zero-based tuple access failed"]
    end
    nested = nested_tuple()
    if (elem(elem(nested, 0), 0) != "nested" or elem(elem(nested, 0), 1) != 7 or elem(nested, 1) != "outer") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "nested tuple access failed"]
    end
    mutable = mutable_tuple()
    mutable = mutable |> put_elem(1, 9) |> put_elem(0, elem(mutable, 0) + 4)
    if (elem(mutable, 0) != 5 or elem(mutable, 1) != 9) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "one-based tuple update failed"]
    end
    zero_based = put_elem(zero_based, 1, 8)
    if (elem(zero_based, 0) != "zero" or elem(zero_based, 1) != 8) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "zero-based tuple update failed"]
    end
    mixed = mixed_object()
    mixed = Map.put(mixed, :_1, "updated")
    if (mixed._1 != "updated" or mixed.label != "mixed") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "mixed anonymous object must remain a map"]
    end
    gapped = gapped_object()
    if (gapped._1 != "map" or gapped._3 != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "gapped anonymous object must remain a map"]
    end
  end
  defp one_based_tuple() do
    {"one", 2}
  end
  defp zero_based_tuple() do
    {"zero", 1}
  end
  defp nested_tuple() do
    {{"nested", 7}, "outer"}
  end
  defp mutable_tuple() do
    {1, 2}
  end
  defp mixed_object() do
    %{_1: "map", label: "mixed"}
  end
  defp gapped_object() do
    %{_1: "map", _3: 3}
  end
end
