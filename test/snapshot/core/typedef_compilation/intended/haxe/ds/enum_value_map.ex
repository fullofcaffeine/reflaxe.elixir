defmodule EnumValueMap do
  def keys(struct) do
    struct.iterator()
  end
  def copy(struct) do
    _ = struct.iterator()
    _ = Enum.each(k, fn item -> copied.set(item, struct.get(item)) end)
    %{}
  end
  def to_string(struct) do
    _ = %StringBuf{}
    _ = StringBuf.add(s, "[")
    _ = struct.iterator()
    _ = Enum.each(it, (fn -> fn item ->
  s.add(inspect(item))
  s.add(" => ")
  s.add(inspect(item.get(item)))
  if (item.has_next.()), do: s.add(", ")
end end).())
    _ = StringBuf.add(s, "]")
    _ = StringBuf.to_string(s)
    _
  end
end
