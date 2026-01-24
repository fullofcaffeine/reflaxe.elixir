defmodule BytesInput do
  def new(bytes, pos_param, len) do
    struct = %{:__reflaxe_class__ => BytesInput, :data => nil, :pos => nil, :remaining => nil, :total_length => nil, :position => nil, :length => nil}
    pos_param = if (Kernel.is_nil(pos_param)) do
      
    else
      pos_param
    end
    len = if (Kernel.is_nil(len)), do: (bytes.length - pos_param), else: len
    if (pos_param < 0 or len < 0 or pos_param + len > bytes.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    struct = %{struct | data: :binary.part(apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes]), pos_param, len)}
    struct = %{struct | pos: 0}
    struct = %{struct | remaining: len}
    struct = %{struct | total_length: len}
    struct
  end
  def get_position(struct) do
    struct.pos
  end
  def get_length(struct) do
    struct.total_length
  end
  def set_position(struct, p) do
    p = cond do
      p < 0 ->
        p = 0
        p
      p > struct.total_length ->
        p = struct.total_length
        p
      :true ->
        :nil
        p
    end
    struct = %{struct | remaining: (struct.total_length - p)}
    struct = %{struct | pos: p}
    struct.pos
  end
  def read_byte(struct) do
    if (struct.remaining == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    struct = %{struct | remaining: (struct.remaining - 1)}
    struct = %{struct | pos: struct.pos + 1}
    :binary.at(struct.data, struct.pos)
  end
  def read_bytes(struct, buf, pos_param, len) do
    if (pos_param < 0 or len < 0 or pos_param + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      if (struct.remaining == 0) do
        raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
      end
      len = if (len > struct.remaining), do: struct.remaining, else: len
      slice = :binary.part(struct.data, struct.pos, len)
      src = Bytes.of_data(slice)
      _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :blit, [buf, pos_param, src, 0, len])
      struct = %{struct | pos: struct.pos + len}
      _ = %{struct | remaining: (struct.remaining - len)}
      len
    end
  end
  def set_big_endian(struct, b) do
    Input.set_big_endian(struct, b)
  end
  def close(struct) do
    Input.close(struct)
  end
  def read_all(struct, bufsize) do
    Input.read_all(struct, bufsize)
  end
  def read_full_bytes(struct, s, pos, len) do
    Input.read_full_bytes(struct, s, pos, len)
  end
  def read(struct, nbytes) do
    Input.read(struct, nbytes)
  end
  def read_until(struct, end_param) do
    Input.read_until(struct, end_param)
  end
  def read_line(struct) do
    Input.read_line(struct)
  end
  def read_float(struct) do
    Input.read_float(struct)
  end
  def read_double(struct) do
    Input.read_double(struct)
  end
  def read_int8(struct) do
    Input.read_int8(struct)
  end
  def read_int16(struct) do
    Input.read_int16(struct)
  end
  def read_u_int16(struct) do
    Input.read_u_int16(struct)
  end
  def read_int24(struct) do
    Input.read_int24(struct)
  end
  def read_u_int24(struct) do
    Input.read_u_int24(struct)
  end
  def read_int32(struct) do
    Input.read_int32(struct)
  end
  def read_string(struct, len, encoding) do
    Input.read_string(struct, len, encoding)
  end
end
