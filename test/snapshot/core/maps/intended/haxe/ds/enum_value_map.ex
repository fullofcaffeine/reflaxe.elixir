defmodule EnumValueMap do
  def new() do
    struct = %{:__reflaxe_class__ => EnumValueMap, :root => nil}
    struct = Map.merge(struct, Map.delete(BalancedTree.new(), :__struct__))
    struct
  end
  defp compare(struct, k1, k2) do
    d = (Type.enum_index(k1) - Type.enum_index(k2))
    if (d != 0) do
      d
    else
      p1 = Type.enum_parameters(k1)
      p2 = Type.enum_parameters(k2)
      if (length(p1) == 0 and length(p2) == 0) do
        0
      else
        compare_args(struct, p1, p2)
      end
    end
  end
  defp compare_args(struct, a1, a2) do
    ld = (length(a1) - length(a2))
    if (ld != 0) do
      ld
    else
      _g = 0
      a1_length = length(a1)
      _ = Enum.each(0..(a1_length - 1)//1, fn i ->
  d = compare_arg(struct, Enum.at(a1, i), Enum.at(a2, i))
  if (d != 0), do: d
end)
    end
  end
  defp compare_arg(struct, v1, v2) do
    cond do
      Reflect.is_enum_value(v1) and Reflect.is_enum_value(v2) -> compare(struct, v1, v2)
      Std.is(v1, Array) and Std.is(v2, Array) -> compare_args(struct, v1, v2)
      :true -> Reflect.compare(v1, v2)
    end
  end
  def set(struct, key, value) do
    BalancedTree.set(struct, key, value)
  end
  def exists(struct, key) do
    BalancedTree.exists(struct, key)
  end
  def keys(struct) do
    BalancedTree.keys(struct)
  end
end
