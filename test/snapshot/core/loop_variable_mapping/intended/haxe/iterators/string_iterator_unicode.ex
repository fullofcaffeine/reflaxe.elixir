defmodule StringIteratorUnicode do
  import Bitwise
  def new(s) do
    %{:offset => 0, :s => s}
  end
  def has_next(struct) do
    struct.offset < struct.s.length
  end
  def next(struct) do
    c = s = struct.s
index = struct.offset + 1
c = s.cca(index)
if (c >= 55296 && c <= 56319) do
  c = c - 55232 <<< 10 ||| s.cca(index + 1) &&& 1023
end
c
    if (c >= 65536), do: struct.offset + 1
    c
  end
  def unicode_iterator(s) do
    StringIteratorUnicode.new(s)
  end
end