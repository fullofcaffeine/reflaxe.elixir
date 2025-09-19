defmodule EnumValueMap do
  defp compare(k1, k2) do
    d = (Type.enum_index(k1) - Type.enum_index(k2))
    if (d != 0), do: d
    p1 = Type.enum_parameters(k1)
    p2 = Type.enum_parameters(k2)
    ld = (length(p1) - length(p2))
    if (ld != 0), do: ld
    if (length(p1) == 0 && length(p2) == 0), do: 0
    struct.compare_args(p1, p2)
  end
  defp compare_args(a1, a2) do
    g = 0
    g1 = length(a1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    d = self.compare_arg(a1[i], a2[i])
    if (d != 0), do: d
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    0
  end
  defp compare_arg(v1, v2) do
    if (is_tuple(v1) and is_atom(elem(v1, 0)) && is_tuple(v2) and is_atom(elem(v2, 0))), do: struct.compare(v1, v2)
    cond do
      v1 < v2 ->
        -1
      v1 > v2 ->
        1
      true ->
        0
    end
  end
  def keys() do
    struct.iterator()
  end
  def copy() do
    copied = %{}
    k = self.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k.has_next()) do
    k2 = acc_k.next()
    Map.put(copied, k2, Map.get(self, k2))
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
    copied
  end
  def to_string() do
    s = StringBuf.new()
    s.add("[")
    it = self.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {it, :ok}, fn _, {acc_it, acc_state} ->
  if (acc_it.has_next()) do
    i2 = acc_it.next()
    s.add(Std.string(i2))
    s.add(" => ")
    s.add(Std.string(Map.get(self, i2)))
    if (acc_it.has_next()), do: s.add(", ")
    {:cont, {acc_it, acc_state}}
  else
    {:halt, {acc_it, acc_state}}
  end
end)
    s.add("]")
    IO.iodata_to_binary(s)
  end
end