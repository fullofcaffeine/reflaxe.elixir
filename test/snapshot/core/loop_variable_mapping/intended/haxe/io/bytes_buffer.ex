defmodule BytesBuffer do
  import Bitwise
  def new() do
    %{:b => Array.new()}
  end
  defp get_length(struct) do
    struct.b.length
  end
  def add_byte(struct, byte) do
    struct.b.push(byte)
  end
  def add(struct, src) do
    b_1 = struct.b
    b_2 = src.b
    g = 0
    g1 = src.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  struct.b.push(b[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def add_string(struct, v, encoding) do
    src = Bytes.of_string(v, encoding)
    b_1 = struct.b
    b_2 = src.b
    g = 0
    g1 = src.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  struct.b.push(b[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def add_int32(struct, v) do
    struct.b.push(v &&& 255)
    struct.b.push(v >>> 8 &&& 255)
    struct.b.push(v >>> 16 &&& 255)
    struct.b.push(v >>> 24)
  end
  def add_int64(struct, v) do
    struct.addInt32(v.low)
    struct.addInt32(v.high)
  end
  def add_float(struct, v) do
    struct.addInt32(FPHelper.float_to_i32(v))
  end
  def add_double(struct, v) do
    struct.addInt64(FPHelper.double_to_i64(v))
  end
  def add_bytes(struct, src, pos, len) do
    if (pos < 0 || len < 0 || pos + len > src.length) do
      throw(:OutsideBounds)
    end
    b_1 = struct.b
    b_2 = src.b
    g = pos
    g1 = pos + len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  struct.b.push(b[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def get_bytes(struct) do
    bytes = Bytes.new(struct.b.length, struct.b)
    b = nil
    bytes
  end
end