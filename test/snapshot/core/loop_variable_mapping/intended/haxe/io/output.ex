defmodule Output do
  import Bitwise
  def write_byte(struct, c) do
    throw(NotImplementedException.new(nil, nil, %{:fileName => "haxe/io/Output.hx", :lineNumber => 47, :className => "haxe.io.Output", :methodName => "writeByte"}))
  end
  def write_bytes(struct, s, pos, len) do
    if (pos < 0 || len < 0 || pos + len > s.length) do
      throw(:OutsideBounds)
    end
    b = s.b
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k > 0) do
  struct.writeByte(b[pos])
  pos + 1
  k - 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    len
  end
  def flush(struct) do
    nil
  end
  def close(struct) do
    nil
  end
  defp set_big_endian(struct, b) do
    bigEndian = b
    b
  end
  def write(struct, s) do
    l = s.length
    p = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (l > 0) do
  k = struct.writeBytes(s, p, l)
  if (k == 0) do
    throw(:Blocked)
  end
  p = p + k
  l = l - k
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def write_full_bytes(struct, s, pos, len) do
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (len > 0) do
  k = struct.writeBytes(s, pos, len)
  pos = pos + k
  len = len - k
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def write_float(struct, x) do
    struct.writeInt32(FPHelper.float_to_i32(x))
  end
  def write_double(struct, x) do
    i_6_4 = FPHelper.double_to_i64(x)
    if (struct.bigEndian) do
      struct.writeInt32(i_6_4.high)
      struct.writeInt32(i_6_4.low)
    else
      struct.writeInt32(i_6_4.low)
      struct.writeInt32(i_6_4.high)
    end
  end
  def write_int8(struct, x) do
    if (x < -128 || x >= 128) do
      throw(:Overflow)
    end
    struct.writeByte(x &&& 255)
  end
  def write_int16(struct, x) do
    if (x < -32768 || x >= 32768) do
      throw(:Overflow)
    end
    struct.writeUInt16(x &&& 65535)
  end
  def write_u_int16(struct, x) do
    if (x < 0 || x >= 65536) do
      throw(:Overflow)
    end
    if (struct.bigEndian) do
      struct.writeByte(x >>> 8)
      struct.writeByte(x &&& 255)
    else
      struct.writeByte(x &&& 255)
      struct.writeByte(x >>> 8)
    end
  end
  def write_int24(struct, x) do
    if (x < -8388608 || x >= 8388608) do
      throw(:Overflow)
    end
    struct.writeUInt24(x &&& 16777215)
  end
  def write_u_int24(struct, x) do
    if (x < 0 || x >= 16777216) do
      throw(:Overflow)
    end
    if (struct.bigEndian) do
      struct.writeByte(x >>> 16)
      struct.writeByte(x >>> 8 &&& 255)
      struct.writeByte(x &&& 255)
    else
      struct.writeByte(x &&& 255)
      struct.writeByte(x >>> 8 &&& 255)
      struct.writeByte(x >>> 16)
    end
  end
  def write_int32(struct, x) do
    if (struct.bigEndian) do
      struct.writeByte(x >>> 24)
      struct.writeByte(x >>> 16 &&& 255)
      struct.writeByte(x >>> 8 &&& 255)
      struct.writeByte(x &&& 255)
    else
      struct.writeByte(x &&& 255)
      struct.writeByte(x >>> 8 &&& 255)
      struct.writeByte(x >>> 16 &&& 255)
      struct.writeByte(x >>> 24)
    end
  end
  def prepare(struct, nbytes) do
    nil
  end
  def write_input(struct, i, bufsize) do
    if (bufsize == nil) do
      bufsize = 4096
    end
    buf = Bytes.alloc(bufsize)
    try do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if true do
  len = i.readBytes(buf, 0, bufsize)
  if (len == 0) do
    throw(:Blocked)
  end
  p = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (len > 0) do
  k = struct.writeBytes(buf, p, len)
  if (k == 0) do
    throw(:Blocked)
  end
  p = p + k
  len = len - k
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
  end
  def write_string(struct, s, encoding) do
    b = Bytes.of_string(s, encoding)
    struct.writeFullBytes(b, 0, b.length)
  end
end