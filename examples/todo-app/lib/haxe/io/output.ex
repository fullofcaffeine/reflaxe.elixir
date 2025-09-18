defmodule Output do
  defp set_big_endian(b) do
    b
  end
  def write_byte(c) do
    nil
  end
  def write_bytes(b, pos, len) do
    if (:nil < :nil || :nil < :nil || :nil + :nil > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k > 0) do
    self.write_byte(:binary.at(b, pos))
    pos = pos + 1
    acc_k = (acc_k - 1)
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
    len
  end
  def write(b) do
    struct.write_bytes(b, 0, b.length)
  end
  def write_input(i, bufsize) do
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
    self.write_bytes(buf, 0, len)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
  end
  def write_string(s) do
    struct.write((Bytes.of_string(s, nil)))
  end
  def flush() do
    nil
  end
  def close() do
    nil
  end
end