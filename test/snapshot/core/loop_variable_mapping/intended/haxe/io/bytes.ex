defmodule Bytes do
  import Bitwise
  defp new(length, b) do
    %{:length => length, :b => b}
  end
  def get(struct, pos) do
    struct.b[pos]
  end
  def set(struct, pos, v) do
    _ = v &&& 255
  end
  def blit(struct, pos, src, srcpos, len) do
    if (pos < 0 || srcpos < 0 || len < 0 || pos + len > struct.length || srcpos + len > src.length) do
      throw(:OutsideBounds)
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
  def fill(struct, pos, len, value) do
    g = 0
    g1 = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  pos = pos + 1
  _ = value &&& 255
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def sub(struct, pos, len) do
    if (pos < 0 || len < 0 || pos + len > struct.length) do
      throw(:OutsideBounds)
    end
    Bytes.new(len, if (end == nil) do
  Enum.slice(struct.b, pos..-1)
else
  Enum.slice(struct.b, pos..pos + len)
end)
  end
  def compare(struct, other) do
    b_1 = struct.b
    b_2 = other.b
    len = if (struct.length < other.length), do: struct.length, else: other.length
    g = 0
    g1 = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  if (b[i] != b[i]) do
    b[i] - b[i]
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    struct.length - other.length
  end
  def get_double(struct, pos) do
    FPHelper.i64_to_double(struct.b[pos] ||| struct.b[pos + 1] <<< 8 ||| struct.b[pos + 2] <<< 16 ||| struct.b[pos + 3] <<< 24, pos = pos + 4
struct.b[pos] ||| struct.b[pos + 1] <<< 8 ||| struct.b[pos + 2] <<< 16 ||| struct.b[pos + 3] <<< 24)
  end
  def get_float(struct, pos) do
    FPHelper.i32_to_float(struct.b[pos] ||| struct.b[pos + 1] <<< 8 ||| struct.b[pos + 2] <<< 16 ||| struct.b[pos + 3] <<< 24)
  end
  def set_double(struct, pos, v) do
    i = FPHelper.double_to_i64(v)
    v = i.low
    _ = v &&& 255
    _ = v >>> 8 &&& 255
    _ = v >>> 16 &&& 255
    _ = v >>> 24 &&& 255
    pos = pos + 4
    v = i.high
    _ = v &&& 255
    _ = v >>> 8 &&& 255
    _ = v >>> 16 &&& 255
    _ = v >>> 24 &&& 255
  end
  def set_float(struct, pos, v) do
    v = FPHelper.float_to_i32(v)
    _ = v &&& 255
    _ = v >>> 8 &&& 255
    _ = v >>> 16 &&& 255
    _ = v >>> 24 &&& 255
  end
  def get_u_int16(struct, pos) do
    struct.b[pos] ||| struct.b[pos + 1] <<< 8
  end
  def set_u_int16(struct, pos, v) do
    _ = v &&& 255
    _ = v >>> 8 &&& 255
  end
  def get_int32(struct, pos) do
    struct.b[pos] ||| struct.b[pos + 1] <<< 8 ||| struct.b[pos + 2] <<< 16 ||| struct.b[pos + 3] <<< 24
  end
  def get_int64(struct, pos) do
    high = pos = pos + 4
struct.b[pos] ||| struct.b[pos + 1] <<< 8 ||| struct.b[pos + 2] <<< 16 ||| struct.b[pos + 3] <<< 24
    low = struct.b[pos] ||| struct.b[pos + 1] <<< 8 ||| struct.b[pos + 2] <<< 16 ||| struct.b[pos + 3] <<< 24
    x = ___Int64.new(high, low)
    this_1 = nil
    this_1 = x
    this_1
  end
  def set_int32(struct, pos, v) do
    _ = v &&& 255
    _ = v >>> 8 &&& 255
    _ = v >>> 16 &&& 255
    _ = v >>> 24 &&& 255
  end
  def set_int64(struct, pos, v) do
    v_1 = v.low
    _ = v &&& 255
    _ = v >>> 8 &&& 255
    _ = v >>> 16 &&& 255
    _ = v >>> 24 &&& 255
    pos = pos + 4
    v = v.high
    _ = v &&& 255
    _ = v >>> 8 &&& 255
    _ = v >>> 16 &&& 255
    _ = v >>> 24 &&& 255
  end
  def get_string(struct, pos, len, encoding) do
    if (encoding == nil), do: encoding == :UTF8
    if (pos < 0 || len < 0 || pos + len > struct.length) do
      throw(:OutsideBounds)
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
  def read_string(struct, pos, len) do
    struct.getString(pos, len)
  end
  def to_string(struct) do
    struct.getString(0, struct.length)
  end
  def to_hex(struct) do
    s_b = nil
    s_b = ""
    chars = []
    str = "0123456789abcdef"
    g = 0
    g1 = str.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  chars.push(str.charCodeAt(i))
  {:cont, acc}
else
  {:halt, acc}
end end)
    g = 0
    g1 = struct.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  c = struct.b[i]
  c_1 = chars[c >>> 4]
  s_b = s_b + String.from_char_code(c)
  c = chars[c &&& 15]
  s_b = s_b + String.from_char_code(c)
  {:cont, acc}
else
  {:halt, acc}
end end)
    s_b
  end
  def get_data(struct) do
    struct.b
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
  def of_data(b) do
    Bytes.new(b.length, b)
  end
  def of_hex(s) do
    len = s.length
    if ((len &&& 1) != 0) do
      throw("Not a hex string (odd number of digits)")
    end
    ret = Bytes.alloc(len >>> 1)
    g = 0
    g1 = ret.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  high = s.cca(i * 2)
  low = s.cca(i * 2 + 1)
  high = (high &&& 15) + ((high &&& 64) >>> 6) * 9
  low = (low &&& 15) + ((low &&& 64) >>> 6) * 9
  _ = (high <<< 4 ||| low) &&& 255 &&& 255
  {:cont, acc}
else
  {:halt, acc}
end end)
    ret
  end
  def fast_get(b, pos) do
    b[pos]
  end
end