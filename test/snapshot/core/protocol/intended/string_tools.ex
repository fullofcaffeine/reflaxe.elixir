defmodule StringTools do
  import Bitwise
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