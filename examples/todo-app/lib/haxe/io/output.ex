defmodule Output do
  defp set_big_endian(_struct, b) do
    b
  end
  def write_byte(_struct, _c) do
    nil
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 || len < 0 || pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, pos, :ok}, fn _, {acc_k, acc_pos, acc_state} ->
  if (acc_k > 0) do
    struct.write_byte(:binary.at(b, pos))
    acc_pos = acc_pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_k, acc_pos, acc_state}}
  else
    {:halt, {acc_k, acc_pos, acc_state}}
  end
end)
    len
  end
  def write(struct, b) do
    struct.write_bytes(b, 0, b.length)
  end
  def write_input(struct, i, bufsize) do
    if (bufsize == nil) do
      bufsize = 4096
    end
    buf = Bytes.alloc(bufsize)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if true do
    len = i.read_bytes(buf, 0, bufsize)
    if (len == 0) do
      throw(:break)
    end
    struct.write_bytes(buf, 0, len)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
  end
  def write_string(struct, s) do
    b = Bytes.of_string(s, nil)
    struct.write(b)
  end
  def flush(_struct) do
    nil
  end
  def close(_struct) do
    nil
  end
end