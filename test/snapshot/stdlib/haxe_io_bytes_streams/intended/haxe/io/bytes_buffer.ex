defmodule BytesBuffer do
  def new() do
    struct = %{:__reflaxe_class__ => BytesBuffer, :parts_reversed => nil, :byte_length => nil, :length => nil}
    struct = %{struct | parts_reversed: []}
    struct = %{struct | byte_length: 0}
    struct
  end
  def get_length(struct) do
    struct.byte_length
  end
  def add_byte(struct, byte) do
    struct = %{struct | parts_reversed: [byte | struct.parts_reversed]}
    struct = %{struct | byte_length: struct.byte_length + 1}
    struct
  end
  def add(struct, src) do
    if (src.length != 0) do
      struct = %{struct | parts_reversed: [apply(Map.get(src, :__reflaxe_class__) || Map.get(src, :__struct__), :get_data, [src]) | struct.parts_reversed]}
      _ = %{struct | byte_length: struct.byte_length + src.length}
    else
      struct
    end
  end
  def add_string(struct, v, encoding) do
    _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :add, [struct, Bytes.of_string(v, encoding)])
  end
  def add_int32(struct, v) do
    struct = %{struct | parts_reversed: [<<v::little-signed-size(32)>> | struct.parts_reversed]}
    struct = %{struct | byte_length: struct.byte_length + 4}
    struct
  end
  def add_int64(struct, v) do
    struct = %{struct | parts_reversed: [<<v::little-signed-size(64)>> | struct.parts_reversed]}
    struct = %{struct | byte_length: struct.byte_length + 8}
    struct
  end
  def add_float(struct, v) do
    struct = %{struct | parts_reversed: [<<v::float-little-size(32)>> | struct.parts_reversed]}
    struct = %{struct | byte_length: struct.byte_length + 4}
    struct
  end
  def add_double(struct, v) do
    struct = %{struct | parts_reversed: [<<v::float-little-size(64)>> | struct.parts_reversed]}
    struct = %{struct | byte_length: struct.byte_length + 8}
    struct
  end
  def add_bytes(struct, src, pos, len) do
    if (pos < 0 or len < 0 or pos + len > src.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len != 0) do
      slice = :binary.part(apply(Map.get(src, :__reflaxe_class__) || Map.get(src, :__struct__), :get_data, [src]), pos, len)
      struct = %{struct | parts_reversed: [slice | struct.parts_reversed]}
      _ = %{struct | byte_length: struct.byte_length + len}
    else
      struct
    end
  end
  def get_bytes(struct) do
    reversed = struct.parts_reversed
    struct = %{struct | parts_reversed: nil}
    _ = %{struct | byte_length: 0}
    binary = :erlang.iolist_to_binary(:lists.reverse(reversed))
    _ = Bytes.of_data(binary)
  end
end
