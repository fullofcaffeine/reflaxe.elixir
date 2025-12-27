defmodule Output do
  def write_byte(struct, c) do
    
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    {pos, k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, fn _, {pos, k} ->
      if (k > 0) do
        _ = write_byte(struct, Bytes.get(b, pos))
        _old_pos = pos
        pos = pos + 1
        old_k = k
        k = (k - 1)
        old_k
        {:cont, {pos, k}}
      else
        {:halt, {pos, k}}
      end
    end)
    nil
    len
  end
  def write(struct, b) do
    write_bytes(struct, b, 0, length(b))
  end
  def write_input(struct, i, bufsize) do
    bufsize = if (Kernel.is_nil(bufsize)) do
      bufsize = 4096
      bufsize
    else
      bufsize
    end
    buf = Bytes.alloc(bufsize)
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  len = Input.read_bytes(i, buf, 0, bufsize)
  if (len == 0) do
    throw(:break)
  end
  _ = write_bytes(struct, buf, 0, len)
  {:cont, acc}
end)
  end
  def write_string(struct, s) do
    b = Bytes.of_string(s, nil)
    _ = write(struct, b)
  end
  def flush(struct) do
    
  end
  def close(struct) do
    
  end
end
