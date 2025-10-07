defmodule EnumValueMap do
  defp compare(struct, k1, k2) do
    d = (Type.enum_index(k1) - Type.enum_index(k2))
    if d != 0, do: d
    p1 = Type.enum_parameters(k1)
    p2 = Type.enum_parameters(k2)
    ld = (length(p1) - length(p2))
    if ld != 0, do: ld
    if length(p1) == 0 and length(p2) == 0, do: 0
    struct.compareArgs(p1, p2)
  end
  defp compare_args(struct, a1, a2) do
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {a1}, fn _, {a1} ->
  if 0 < length(a1) do
    i = 0 + 1
    d = struct.compareArg(a1[i], a2[i])
    if d != 0, do: d
    {:cont, {a1}}
  else
    {:halt, {a1}}
  end
end)
    0
  end
  defp compare_arg(struct, v1, v2) do
    if Reflect.is_enum_value(v1) and Reflect.is_enum_value(v2), do: struct.compare(v1, v2)
    Reflect.compare(v1, v2)
  end
  def keys(struct) do
    struct.iterator()
  end
  def copy(struct) do
    copied = %{}
    k = struct.iterator()
    Enum.each(k, fn {name, hex} -> copied.set(k2, struct.get(k2)) end)
    copied
  end
  def to_string(struct) do
    s = StringBuf.new()
    StringBuf.add(s, "[")
    it = struct.iterator()
    Enum.each(it, fn {name, hex} ->
  s.add(inspect(i2))
  s.add(" => ")
  s.add(inspect(struct.get(i2)))
  if it.hasNext.(), do: s.add(", ")
end)
    StringBuf.add(s, "]")
    StringBuf.to_string(s)
  end
end