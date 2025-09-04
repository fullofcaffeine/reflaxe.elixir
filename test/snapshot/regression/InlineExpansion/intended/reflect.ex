defmodule Reflect do
  def field(obj, field) do
    Map.get(obj, String.to_existing_atom(field))
  end
  def set_field(obj, field, value) do
    Map.put(obj, String.to_atom(field), value)
  end
  def fields(obj) do
    Map.keys(obj) |> Enum.map(&Atom.to_string/1)
  end
  def compare(a, b) do
    sa = Std.string(a)
    sb = Std.string(b)
    if (sa < sb), do: -1
    if (sa > sb), do: 1
    0
  end
end