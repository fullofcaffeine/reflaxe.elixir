defmodule Input do
  import Bitwise
  def read_byte(struct) do
    throw(NotImplementedException.new(nil, nil, %{:fileName => "haxe/io/Input.hx", :lineNumber => 53, :className => "haxe.io.Input", :methodName => "readByte"}))
  end
  def read_bytes(struct, s, pos, len) do
    k = len
    b = s.b
    if (pos < 0 || len < 0 || pos + len > s.length) do
      throw(:OutsideBounds)
    end
    try do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k > 0) do
  _ = struct.readByte()
  pos + 1
  k - 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    rescue
      eof ->
        nil
    end
    len - k
  end
  def close(struct) do
    nil
  end
  defp set_big_endian(struct, b) do
    bigEndian = b
    b
  end
  def read_all(struct, bufsize) do
    if (bufsize == nil) do
      bufsize = 16384
    end
    buf = Bytes.alloc(bufsize)
    total = BytesBuffer.new()
    try do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if true do
  len = struct.readBytes(buf, 0, bufsize)
  if (len == 0) do
    throw(:Blocked)
  end
  if (len < 0 || len > buf.length) do
    throw(:OutsideBounds)
  end
  b_1 = total.b
  b_2 = buf.b
  g = 0
  g1 = len
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  total.b.push(b[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
  {:cont, acc}
else
  {:halt, acc}
end end)
    rescue
      e ->
        nil
    end
    total.getBytes()
  end
  def read_full_bytes(struct, s, pos, len) do
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (len > 0) do
  k = struct.readBytes(s, pos, len)
  if (k == 0) do
    throw(:Blocked)
  end
  pos = pos + k
  len = len - k
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def read(struct, nbytes) do
    s = Bytes.alloc(nbytes)
    p = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (nbytes > 0) do
  k = struct.readBytes(s, p, nbytes)
  if (k == 0) do
    throw(:Blocked)
  end
  p = p + k
  nbytes = nbytes - k
  {:cont, acc}
else
  {:halt, acc}
end end)
    s
  end
  def read_until(struct, end) do
    buf = BytesBuffer.new()
    last = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if ((last = struct.readByte()) != end) do
  buf.b.push(last)
  {:cont, acc}
else
  {:halt, acc}
end end)
    buf.getBytes().toString()
  end
  def read_line(struct) do
    buf = BytesBuffer.new()
    last = nil
    s = nil
    try do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if ((last = struct.readByte()) != 10) do
  buf.b.push(last)
  {:cont, acc}
else
  {:halt, acc}
end end)
      s = buf.getBytes().toString()
      if (s.charCodeAt(s.length - 1) == 13) do
        s = s.substr(0, -1)
      end
    rescue
      e ->
        s = buf.getBytes().toString()
        if (s.length == 0) do
          throw(e)
        end
    end
    s
  end
  def read_float(struct) do
    FPHelper.i32_to_float(struct.readInt32())
  end
  def read_double(struct) do
    i_1 = struct.readInt32()
    i_2 = struct.readInt32()
    if (struct.bigEndian) do
      FPHelper.i64_to_double(i, i)
    else
      FPHelper.i64_to_double(i, i)
    end
  end
  def read_int8(struct) do
    n = struct.readByte()
    if (n >= 128), do: n - 256
    n
  end
  def read_int16(struct) do
    ch_1 = struct.readByte()
    ch_2 = struct.readByte()
    n = if (struct.bigEndian), do: ch ||| ch <<< 8, else: ch ||| ch <<< 8
    if ((n &&& 32768) != 0), do: n - 65536
    n
  end
  def read_u_int16(struct) do
    ch_1 = struct.readByte()
    ch_2 = struct.readByte()
    if (struct.bigEndian), do: ch ||| ch <<< 8, else: ch ||| ch <<< 8
  end
  def read_int24(struct) do
    ch_1 = struct.readByte()
    ch_2 = struct.readByte()
    ch_3 = struct.readByte()
    n = if (struct.bigEndian), do: ch ||| ch <<< 8 ||| ch <<< 16, else: ch ||| ch <<< 8 ||| ch <<< 16
    if ((n &&& 8388608) != 0), do: n - 16777216
    n
  end
  def read_u_int24(struct) do
    ch_1 = struct.readByte()
    ch_2 = struct.readByte()
    ch_3 = struct.readByte()
    if (struct.bigEndian), do: ch ||| ch <<< 8 ||| ch <<< 16, else: ch ||| ch <<< 8 ||| ch <<< 16
  end
  def read_int32(struct) do
    ch_1 = struct.readByte()
    ch_2 = struct.readByte()
    ch_3 = struct.readByte()
    ch_4 = struct.readByte()
    if (struct.bigEndian), do: ch ||| ch <<< 8 ||| ch <<< 16 ||| ch <<< 24, else: ch ||| ch <<< 8 ||| ch <<< 16 ||| ch <<< 24
  end
  def read_string(struct, len, encoding) do
    b = Bytes.alloc(len)
    struct.readFullBytes(b, 0, len)
    b.getString(0, len, encoding)
  end
end