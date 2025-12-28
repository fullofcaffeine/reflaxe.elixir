defmodule Output do
  def write_byte(_, _) do
    
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    {_pos, _k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, k}, fn _, {acc_pos, acc_k} ->
      try do
        if (acc_k > 0) do
          _ = write_byte(struct, Bytes.get(b, acc_pos))
          acc_pos = acc_pos + 1
          acc_k = (acc_k - 1)
          {:cont, {acc_pos, acc_k}}
        else
          {:halt, {acc_pos, acc_k}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_pos, acc_k}}
        :throw, :continue ->
          {:cont, {acc_pos, acc_k}}
      end
    end)
    len
  end
  def write(struct, b) do
    write_bytes(struct, b, 0, length(b))
  end
  def write_input(struct, i, bufsize) do
    bufsize = if (Kernel.is_nil(bufsize)), do: 4096, else: bufsize
    buf = Bytes.alloc(bufsize)
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    len = Input.read_bytes(i, buf, 0, bufsize)
    if (len == 0) do
      throw({:break, acc})
    end
    _ = write_bytes(struct, buf, 0, len)
    {:cont, acc}
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
  end
  def write_string(struct, s) do
    b = Bytes.of_string(s, nil)
    _ = write(struct, b)
  end
  def flush(_) do
    
  end
  def close(_) do
    
  end
end
