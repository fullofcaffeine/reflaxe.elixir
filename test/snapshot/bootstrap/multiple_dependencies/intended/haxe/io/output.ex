defmodule Output do
  def write_byte(_struct, _c) do
    
  end
  def write_bytes(_struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      throw("Invalid parameters")
    end
    k = len
    _ = Enum.each(k, (fn -> fn item ->
  item.writeByte(item.get(item))
  item + 1
  (item - 1)
end end).())
    len
  end
  def write(struct, b) do
    struct.writeBytes(b, 0, length(b))
  end
  def write_input(_struct, _i, _bufsize) do
    if (Kernel.is_nil(bufsize)) do
      bufsize = 4096
    end
    buf = MyApp.Bytes.alloc(bufsize)
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, (fn -> fn _, acc ->
  if (true) do
    len = i.readBytes(buf, 0, bufsize)
    if (len == 0) do
      throw(:break)
    end
    struct.writeBytes(buf, 0, len)
    {:cont, acc}
  else
    {:halt, acc}
  end
end end).())
  end
  def write_string(struct, _s) do
    b = MyApp.Bytes.of_string(s, nil)
    _ = struct.write(b)
  end
  def flush(_struct) do
    
  end
  def close(_struct) do
    
  end
end
