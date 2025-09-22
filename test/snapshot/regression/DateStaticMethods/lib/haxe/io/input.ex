defmodule Input do
  defp set_big_endian(struct, b) do
    b
  end
  def read_byte(struct) do
    -1
  end
  def read_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k > 0) do
    byte = struct.read_byte()
    if (byte < 0) do
      throw(:break)
    end
    b.set(pos, byte)
    pos = pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, len, :ok}, fn _, {acc_total, acc_len, acc_state} -> nil end)
    total
  end
  def read_string(struct, len) do
    b = Bytes.alloc(len)
    actual = struct.read_bytes(b, 0, len)
    if (actual < len) do
      smaller = Bytes.alloc(actual)
      smaller.blit(0, b, 0, actual)
      b = smaller
    end
    b.to_string()
  end
  def read_line(struct) do
    buf = StringBuf.new()
    last = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {last, :ok}, fn _, {acc_last, acc_state} ->
  if ((acc_last = struct.read_byte()) >= 0) do
    if (acc_last == 10) do
      throw(:break)
    end
    if (acc_last != 13), do: buf.add_char(acc_last)
    {:cont, {acc_last, acc_state}}
  else
    {:halt, {acc_last, acc_state}}
  end
end)
    IO.iodata_to_binary(buf)
  end
  def close(struct) do
    nil
  end
end