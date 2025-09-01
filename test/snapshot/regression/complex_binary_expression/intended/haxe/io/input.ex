defmodule Input do
  import Bitwise
  defp set_big_endian(struct, b) do
    bigEndian = b
    b
  end
  def read_byte(struct) do
    -1
  end
  def read_bytes(struct, b, pos, len) do
    if (pos < 0 || len < 0 || pos + len > b.length) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (k > 0) do
    byte = struct.readByte()
    if (byte < 0) do
      throw(:break)
    end
    _ = byte &&& 255
    pos = pos + 1
    k = (k - 1)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    (len - k)
  end
  def read_all(struct, bufsize) do
    if (bufsize == nil) do
      bufsize = 4096
    end
    buf = Bytes.alloc(bufsize)
    total = Bytes.alloc(0)
    len = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if true do
    n = struct.readBytes(buf, 0, bufsize)
    if (n == 0) do
      throw(:break)
    end
    new_total = Bytes.alloc(len + n)
    new_total.blit(0, total, 0, len)
    new_total.blit(len, buf, 0, n)
    total = new_total
    len = len + n
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    total
  end
  def read_string(struct, len) do
    b = Bytes.alloc(len)
    actual = struct.readBytes(b, 0, len)
    if (actual < len) do
      smaller = Bytes.alloc(actual)
      smaller.blit(0, b, 0, actual)
      b = smaller
    end
    b.toString()
  end
  def read_line(struct) do
    buf_b = nil
    buf_b = ""
    last = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if ((last = struct.readByte()) >= 0) do
    if (last == 10) do
      throw(:break)
    end
    if (last != 13) do
      buf_b = buf_b <> String.from_char_code(last)
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    buf_b
  end
  def close(struct) do
    nil
  end
end