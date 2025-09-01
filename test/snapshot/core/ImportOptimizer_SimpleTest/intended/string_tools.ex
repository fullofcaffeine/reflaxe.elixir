defmodule StringTools do
  def is_space(s, pos) do
    c = s.charCodeAt(pos)
    c > 8 && c < 14 || c == 32
  end
  def ltrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (r < l && StringTools.is_space(s, r)) do
  r + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    if (r > 0), do: s.substr(r, l - r), else: s
  end
  def rtrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (r < l && StringTools.is_space(s, l - r - 1)) do
  r + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    if (r > 0), do: s.substr(0, l - r), else: s
  end
  def trim(s) do
    StringTools.ltrim(StringTools.rtrim(s))
  end
  def replace(s, sub, by) do
    Enum.join(s.split(sub), by)
  end
end