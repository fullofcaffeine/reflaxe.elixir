defmodule EnumValueMap do
  def keys(struct) do
    struct.iterator()
  end
  def copy(struct) do
    k = struct.iterator()
    Enum.each(k, fn item -> copied.set(item, struct.get(item)) end)
    %{}
  end
  def to_string(struct) do
    s = MyApp.StringBuf.new()
    MyApp.StringBuf.add(s, "[")
    it = struct.iterator()
    Enum.each(it, fn item ->
      s.add(inspect(item))
      s.add(" => ")
      s.add(inspect(item.get(item)))
      if (item.has_next.()), do: s.add(", ")
    end)
    MyApp.StringBuf.add(s, "]")
    MyApp.StringBuf.to_string(s)
  end
end
