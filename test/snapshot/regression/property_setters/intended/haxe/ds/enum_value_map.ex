defmodule EnumValueMap do
  def new() do
    %{}
  end
  defp compare(struct, k1, k2) do
    d = (Type.enum_index(k1) - Type.enum_index(k2))
    if (d != 0), do: d
    p1 = Type.enum_parameters(k1)
    p2 = Type.enum_parameters(k2)
    if (p1.length == 0 && p2.length == 0), do: 0
    struct.compareArgs(p1, p2)
  end
  defp compare_args(struct, a1, a2) do
    ld = (a1.length - a2.length)
    if (ld != 0), do: ld
    g = 0
    g1 = a1.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    d = struct.compareArg(a1[i], a2[i])
    if (d != 0), do: d
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    0
  end
  defp compare_arg(struct, v1, v2) do
    if (is_tuple(v1) and is_atom(elem(v1, 0)) && is_tuple(v2) and is_atom(elem(v2, 0))) do
      struct.compare(v1, v2)
    else
      if (Std.is(v1, Array) && Std.is(v2, Array)) do
        struct.compareArgs(v1, v2)
      else
        cond do
          v1 < v2 ->
            -1
          v1 > v2 ->
            1
          true ->
            0
        end
      end
    end
  end
  def copy(struct) do
    copied = %{}
    root = struct[:root]
    copied
  end
end