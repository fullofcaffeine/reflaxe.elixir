defmodule BytesOutput do
  def new() do
    struct = %{:__reflaxe_class__ => BytesOutput, :buffer => nil, :length => nil}
    struct = %{struct | buffer: BytesBuffer.new()}
    struct
  end
  def get_length(struct) do
    struct.buffer.byte_length
  end
  def write_byte(struct, c) do
    this = struct.buffer
    _parts_reversed = [c | _this.parts_reversed]
    byte_length = this.byte_length + 1
    byte_length
  end
  def write_bytes(struct, buf, pos, len) do
    this = struct.buffer
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      nil
    else
      slice = :binary.part(apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :get_data, [buf]), pos, len)
      _parts_reversed = [slice | _this.parts_reversed]
      _byte_length = this.byte_length + len
    end
    len
  end
  def get_bytes(struct) do
    current = struct.buffer
    _ = %{struct | buffer: nil}
    _ = apply(Map.get(current, :__reflaxe_class__) || Map.get(current, :__struct__), :get_bytes, [current])
  end
  def set_big_endian(struct, b) do
    Output.set_big_endian(struct, b)
  end
  def flush(struct) do
    Output.flush(struct)
  end
  def close(struct) do
    Output.close(struct)
  end
  def write(struct, s) do
    Output.write(struct, s)
  end
  def write_full_bytes(struct, s, pos, len) do
    Output.write_full_bytes(struct, s, pos, len)
  end
  def write_float(struct, x) do
    Output.write_float(struct, x)
  end
  def write_double(struct, x) do
    Output.write_double(struct, x)
  end
  def write_int8(struct, x) do
    Output.write_int8(struct, x)
  end
  def write_int16(struct, x) do
    Output.write_int16(struct, x)
  end
  def write_u_int16(struct, x) do
    Output.write_u_int16(struct, x)
  end
  def write_int24(struct, x) do
    Output.write_int24(struct, x)
  end
  def write_u_int24(struct, x) do
    Output.write_u_int24(struct, x)
  end
  def write_int32(struct, x) do
    Output.write_int32(struct, x)
  end
  def prepare(struct, nbytes) do
    Output.prepare(struct, nbytes)
  end
  def write_input(struct, i, bufsize) do
    Output.write_input(struct, i, bufsize)
  end
  def write_string(struct, s, encoding) do
    Output.write_string(struct, s, encoding)
  end
end
