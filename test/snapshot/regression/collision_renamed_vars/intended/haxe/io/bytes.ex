defmodule Bytes do
  import Bitwise
  defp new(length, b) do
    %{:length => length, :b => b}
  end
  def blit(struct, pos, src, srcpos, len) do
    if (pos < 0 || srcpos < 0 || len < 0 || pos + len > struct.length || srcpos + len > src.length) do
      throw(:outside_bounds)
    end
    b_1 = struct.b
    b_2 = src.b
    if (b == b && pos > srcpos) do
      i = len
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i > 0) do
  i - 1
  _ = b[i + srcpos]
  {:cont, acc}
else
  {:halt, acc}
end end)
      nil
    end
    g = 0
    g1 = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  _ = b[i + srcpos]
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def get_string(struct, pos, len, encoding) do
    if (encoding == nil), do: encoding == :utf8
    if (pos < 0 || len < 0 || pos + len > struct.length) do
      throw(:outside_bounds)
    end
    s = ""
    b = struct.b
    fcc = String.fromCharCode
    i = pos
    max = pos + len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < max) do
  c = b[i + 1]
  if (c < 128) do
    if (c == 0) do
      throw(:break)
    end
    s = s + fcc.(c)
  else
    if (c < 224) do
      s = s + fcc.((c &&& 63) <<< 6 ||| b[i + 1] &&& 127)
    else
      if (c < 240) do
        c_2 = b[i + 1]
        s = s + fcc.((c &&& 31) <<< 12 ||| (c &&& 127) <<< 6 ||| b[i + 1] &&& 127)
      else
        c_2 = b[i + 1]
        c_3 = b[i + 1]
        u = (c &&& 15) <<< 18 ||| (c &&& 127) <<< 12 ||| (c &&& 127) <<< 6 ||| b[i + 1] &&& 127
        s = s + fcc.((u >>> 10) + 55232)
        s = s + fcc.(u &&& 1023 ||| 56320)
      end
    end
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    s
  end
  def to_string(struct) do
    struct.getString(0, struct.length)
  end
  def alloc(length) do
    a = Array.new()
    g = 0
    g1 = length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  a.push(0)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Bytes.new(length, a)
  end
  def of_string(s, encoding) do
    a = Array.new()
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < s.length) do
  c = index = i + 1
s.cca(index)
  if (55296 <= c && c <= 56319) do
    c = c - 55232 <<< 10 ||| index = i + 1
s.cca(index) &&& 1023
  end
  if (c <= 127) do
    a.push(c)
  else
    if (c <= 2047) do
      a.push(192 ||| c >>> 6)
      a.push(128 ||| c &&& 63)
    else
      if (c <= 65535) do
        a.push(224 ||| c >>> 12)
        a.push(128 ||| c >>> 6 &&& 63)
        a.push(128 ||| c &&& 63)
      else
        a.push(240 ||| c >>> 18)
        a.push(128 ||| c >>> 12 &&& 63)
        a.push(128 ||| c >>> 6 &&& 63)
        a.push(128 ||| c &&& 63)
      end
    end
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    Bytes.new(a.length, a)
  end
end