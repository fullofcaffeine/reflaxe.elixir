defmodule Input do
  defp set_big_endian(b) do
    b
  end
  def read_byte() do
    -1
  end
  def read_bytes(b, pos, len) do
    if (:nil < :nil || :nil < :nil || :nil + :nil > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k > 0) do
    byte = self.read_byte()
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
  def read_all(bufsize) do
    if (bufsize == nil) do
      bufsize = 4096
    end
    buf = Bytes.alloc(bufsize)
    total = Bytes.alloc(0)
    len = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, len, :ok}, fn _, {acc_total, acc_len, acc_state} -> nil end)
    total
  end
  def read_string(len) do
    b = Bytes.alloc(len)
    actual = self.read_bytes(b, 0, len)
    if (actual < len) do
      smaller = Bytes.alloc(actual)
      smaller.blit(0, b, 0, actual)
      b = smaller
    end
    b.to_string()
  end
  def read_line() do
    buf = StringBuf.new()
    last = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {last, :ok}, fn _, {acc_last, acc_state} -> nil end)
    IO.iodata_to_binary(buf)
  end
  def close() do
    nil
  end
end