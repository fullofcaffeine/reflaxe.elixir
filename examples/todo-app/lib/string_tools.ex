defmodule StringTools do
  import Bitwise
  def is_space(s, pos) do
    c = s.charCodeAt(pos)
    c > 8 && c < 14 || c == 32
  end
  def ltrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {r, :ok}, fn _, {acc_r, acc_state} ->
  r = acc_r
  if (r < l && is_space(s, r)) do
    r = r + 1
    {:cont, {r, acc_state}}
  else
    {:halt, {r, acc_state}}
  end
end)
    if (r > 0), do: s.substr(r, (l - r)), else: s
  end
  def rtrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {r, :ok}, fn _, {acc_r, acc_state} ->
  r = acc_r
  if (r < l && is_space(s, ((l - r) - 1))) do
    r = r + 1
    {:cont, {r, acc_state}}
  else
    {:halt, {r, acc_state}}
  end
end)
    if (r > 0), do: s.substr(0, (l - r)), else: s
  end
  def trim(s) do
    ltrim(rtrim(s))
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, n, :ok}, fn _, {acc_s, acc_n, acc_state} ->
  s = acc_s
  n = acc_n
  if (n > 0) do
    s = hex_chars.charAt(n &&& 15) <> s
    n = n + 4
    {:cont, {s, n, acc_state}}
  else
    {:halt, {s, n, acc_state}}
  end
end)
    if (digits != nil) do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, :ok}, fn _, {acc_s, acc_state} ->
  s = acc_s
  if (s.length < digits) do
    s = "0" <> s
    {:cont, {s, acc_state}}
  else
    {:halt, {s, acc_state}}
  end
end)
    end
    s
  end
end