defmodule BytesOutput do
  def new() do
    struct = %{:buffer => nil, :length => nil}
    struct = %{struct | buffer: %BytesBuffer{}}
    struct
  end
  def write_byte(struct, c) do
    this = struct.buffer
    _parts_reversed = [c | _this.parts_reversed]
    byte_length = this.byte_length + 1
    byte_length
  end
  def write_bytes(struct, buf, pos, len) do
    this = struct.buffer
    if (pos < 0 or len < 0 or pos + len > length(buf)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      nil
    else
      slice = :binary.part(Bytes.get_data(buf), pos, len)
      _parts_reversed = [slice | _this.parts_reversed]
      _byte_length = this.byte_length + len
    end
    len
  end
  def get_bytes(struct) do
    current = struct.buffer
    _ = %{struct | buffer: nil}
    _ = BytesBuffer.get_bytes(current)
  end
end
