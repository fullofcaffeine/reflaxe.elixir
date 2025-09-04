defmodule Output do
  defp set_big_endian(struct, b) do
    bigEndian = b
    b
  end
  def write_byte(_struct, _c) do
    nil
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 || len < 0 || pos + len > b.length) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, k, :ok}, fn _, {acc_pos, acc_k, acc_state} ->
  if (acc_k > 0) do
    struct.writeByte(:binary.at(b, pos))
    acc_pos = acc_pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_pos, acc_k, acc_state}}
  else
    {:halt, {acc_pos, acc_k, acc_state}}
  end
end)
    len
  end
  def write(struct, b) do
    struct.writeBytes(b, 0, b.length)
  end
  def write_input(struct, i, bufsize) do
    if (bufsize == nil) do
      bufsize = 4096
    end
    buf = Bytes.alloc(bufsize)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if true do
    len = i.readBytes(buf, 0, bufsize)
    if (len == 0) do
      throw(:break)
    end
    struct.writeBytes(buf, 0, len)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
  end
  def write_string(struct, s) do
    b = Bytes.of_string(s)
    struct.write(b)
  end
  def flush(_struct) do
    nil
  end
  def close(_struct) do
    nil
  end
end