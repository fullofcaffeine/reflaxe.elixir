defmodule Input do
  defp set_big_endian(struct, b) do
    bigEndian = b
    b
  end
  def read_byte(_struct) do
    -1
  end
  def read_bytes(struct, b, pos, len) do
    if (pos < 0 || len < 0 || pos + len > b.length) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, k, :ok}, fn _, {acc_pos, acc_k, acc_state} ->
  if (acc_k > 0) do
    byte = struct.readByte()
    if (byte < 0) do
      throw(:break)
    end
    b.set(acc_pos, byte)
    acc_pos = acc_pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_pos, acc_k, acc_state}}
  else
    {:halt, {acc_pos, acc_k, acc_state}}
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, len, :ok}, fn _, {acc_total, acc_len, acc_state} ->
  if true do
    n = struct.readBytes(buf, 0, bufsize)
    if (n == 0) do
      throw(:break)
    end
    new_total = Bytes.alloc(acc_len + n)
    new_total.blit(0, acc_total, 0, acc_len)
    new_total.blit(acc_len, buf, 0, n)
    acc_total = new_total
    acc_len = acc_len + n
    {:cont, {acc_total, acc_len, acc_state}}
  else
    {:halt, {acc_total, acc_len, acc_state}}
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
    buf = StringBuf.new()
    last = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {last, :ok}, fn _, {acc_last, acc_state} ->
  if (acc_last >= 0) do
    if (acc_last == 10) do
      throw(:break)
    end
    if (acc_last != 13), do: buf.addChar(acc_last)
    {:cont, {acc_last, acc_state}}
  else
    {:halt, {acc_last, acc_state}}
  end
end)
    IO.iodata_to_binary(buf)
  end
  def close(_struct) do
    nil
  end
end