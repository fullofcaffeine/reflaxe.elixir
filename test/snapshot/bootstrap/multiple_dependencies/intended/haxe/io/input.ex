defmodule Input do
  def read_byte(struct) do
    -1
  end
  def read_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k}, (fn -> fn _, {k} ->
  if (k > 0) do
    byte = struct.readByte()
    if (byte < 0) do
      throw(:break)
    end
    b.set(pos, byte)
    pos + 1
    (k - 1)
    {:cont, {k}}
  else
    {:halt, {k}}
  end
end end).())
    (len - k)
  end
  def read_all(struct, bufsize) do
    if (Kernel.is_nil(bufsize)) do
      bufsize = 4096
    end
    buf = MyApp.Bytes.alloc(bufsize)
    len = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, len}, (fn -> fn _, {total, len} ->
  if (true) do
    n = struct.readBytes(buf, 0, bufsize)
    if (n == 0) do
      throw(:break)
    end
    new_total = Bytes.alloc(len + n)
    new_total.blit(0, total, 0, len)
    new_total.blit(len, buf, 0, n)
    total = new_total
    len = len + n
    {:cont, {total, len}}
  else
    {:halt, {total, len}}
  end
end end).())
    MyApp.Bytes.alloc(0)
  end
  def read_string(struct, len) do
    b = MyApp.Bytes.alloc(len)
    actual = struct.readBytes(b, 0, len)
    if (actual < len) do
      smaller = MyApp.Bytes.alloc(actual)
      _ = smaller.blit(0, b, 0, actual)
      _b = smaller
    end
    _ = StringBuf.to_string(b)
  end
  def read_line(struct) do
    buf = %StringBuf{}
    last = nil
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {last}, (fn -> fn _, {last} ->
  if (last = struct.readByte() >= 0) do
    if (last == 10) do
      throw(:break)
    end
    if (last != 13), do: buf.addChar(last)
    {:cont, {last}}
  else
    {:halt, {last}}
  end
end end).())
    _ = StringBuf.to_string(buf)
  end
  def close(struct) do
    
  end
end
