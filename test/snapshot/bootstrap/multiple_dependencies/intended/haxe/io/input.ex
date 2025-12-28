defmodule Input do
  def read_byte(_) do
    -1
  end
  def read_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    {_b, _pos, k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {b, pos, k}, fn _, {acc_b, acc_pos, acc_k} ->
      try do
        if (acc_k > 0) do
          byte = read_byte(struct)
          if (byte < 0) do
            throw({:break, {acc_b, acc_pos, acc_k}})
          end
          acc_b = Bytes.set(acc_b, acc_pos, byte)
          acc_pos = acc_pos + 1
          acc_k = (acc_k - 1)
          {:cont, {acc_b, acc_pos, acc_k}}
        else
          {:halt, {acc_b, acc_pos, acc_k}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_b, acc_pos, acc_k}}
        :throw, :continue ->
          {:cont, {acc_b, acc_pos, acc_k}}
      end
    end)
    (len - k)
  end
  def read_all(struct, bufsize) do
    bufsize = if (Kernel.is_nil(bufsize)), do: 4096, else: bufsize
    buf = Bytes.alloc(bufsize)
    total = Bytes.alloc(0)
    len = 0
    {total, _len} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, len}, fn _, {acc_total, acc_len} ->
      try do
        n = read_bytes(struct, buf, 0, bufsize)
        if (n == 0) do
          throw({:break, {acc_total, acc_len}})
        end
        new_total = Bytes.alloc(acc_len + n)
        new_total = Bytes.blit(new_total, 0, acc_total, 0, acc_len)
        new_total = Bytes.blit(new_total, acc_len, buf, 0, n)
        acc_total = new_total
        acc_len = acc_len + n
        {:cont, {acc_total, acc_len}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_total, acc_len}}
        :throw, :continue ->
          {:cont, {acc_total, acc_len}}
      end
    end)
    total
  end
  def read_string(struct, len) do
    b = Bytes.alloc(len)
    actual = read_bytes(struct, b, 0, len)
    b = if (actual < len) do
      smaller = Bytes.alloc(actual)
      smaller = Bytes.blit(smaller, 0, b, 0, actual)
      smaller
    else
      b
    end
    _ = Bytes.to_string(b)
  end
  def read_line(struct) do
    buf = %StringBuf{}
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if ((last = read_byte(struct)) >= 0) do
      if (last == 10) do
        throw({:break, acc})
      end
      if (last != 13) do
        StringBuf.add_char(buf, last)
      end
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
    _ = StringBuf.to_string(buf)
  end
  def close(_) do
    
  end
end
