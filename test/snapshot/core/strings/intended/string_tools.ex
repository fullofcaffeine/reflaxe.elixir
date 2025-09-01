defmodule StringTools do
  import Bitwise
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
  def lpad(s, c, l) do
    if (c.length <= 0), do: s
    buf_b = nil
    buf_b = ""
    l = l - s.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (buf_b.length < l) do
  buf_b = buf_b + Std.string(c)
  {:cont, acc}
else
  {:halt, acc}
end end)
    buf_b = buf_b + Std.string(s)
    buf_b
  end
  def rpad(s, c, l) do
    if (c.length <= 0), do: s
    buf_b = nil
    buf_b = ""
    buf_b = buf_b + Std.string(s)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (buf_b.length < l) do
  buf_b = buf_b + Std.string(c)
  {:cont, acc}
else
  {:halt, acc}
end end)
    buf_b
  end
  def replace(s, sub, by) do
    Enum.join(s.split(sub), by)
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (n > 0) do
  s = hex_chars.charAt(n &&& 15) + s
  n = n + 4
  {:cont, acc}
else
  {:halt, acc}
end end)
    if (digits != nil) do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (s.length < digits) do
  s = "0" + s
  {:cont, acc}
else
  {:halt, acc}
end end)
    end
    s
  end
end