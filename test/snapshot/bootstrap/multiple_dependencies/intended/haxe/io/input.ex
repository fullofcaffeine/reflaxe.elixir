defmodule Input do
  def read_byte(struct) do
    -1
  end
  def read_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    {b, pos, k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {b, 0, 0}, fn _, {b, pos, k} ->
      if (k > 0) do
        byte = read_byte(struct)
        if (byte < 0) do
          throw(:break)
        end
        _ = Bytes.set(b, pos, byte)
        _old_pos = pos
        pos = pos + 1
        old_k = k
        k = (k - 1)
        old_k
        {:cont, {b, pos, k}}
      else
        {:halt, {b, pos, k}}
      end
    end)
    nil
    (len - k)
  end
  def read_all(struct, bufsize) do
    bufsize = if (Kernel.is_nil(bufsize)) do
      bufsize = 4096
      bufsize
    else
      bufsize
    end
    buf = Bytes.alloc(bufsize)
    len = 0
    {total, len} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, 0}, fn _, {total, len} ->
      n = read_bytes(struct, buf, 0, bufsize)
      if (n == 0) do
        throw(:break)
      end
      new_total = Bytes.alloc(len + n)
      _ = Bytes.blit(new_total, 0, total, 0, len)
      _ = Bytes.blit(new_total, len, buf, 0, n)
      _total = new_total
      len = len + n
      {:cont, {total, len}}
    end)
    nil
    Bytes.alloc(0)
  end
  def read_string(struct, len) do
    b = Bytes.alloc(len)
    actual = read_bytes(struct, b, 0, len)
    b = if (actual < len) do
      smaller = Bytes.alloc(actual)
      _ = Bytes.blit(smaller, 0, b, 0, actual)
      b = smaller
      b
    else
      b
    end
    _ = Bytes.to_string(b)
  end
  def read_line(struct) do
    buf = %StringBuf{}
    last = nil
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (last = read_byte(struct) >= 0) do
    if (last == 10) do
      throw(:break)
    end
    if (last != 13) do
      StringBuf.add_char(buf, last)
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    _ = StringBuf.to_string(buf)
  end
  def close(struct) do
    
  end
end
