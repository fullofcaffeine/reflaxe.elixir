defmodule BytesBuffer do
  def new() do
    struct = %{:parts_reversed => nil, :byte_length => nil, :length => nil}
    struct = %{struct | parts_reversed: []}
    struct = %{struct | byte_length: 0}
    struct
  end
  def add_byte(struct, byte) do
    struct = %{struct | parts_reversed: [byte | struct.parts_reversed]}
    struct = %{struct | byte_length: struct.byte_length + 1}
    struct
  end
  def add(struct, src) do
    if (length(src) == 0) do
      nil
    else
      struct = %{struct | parts_reversed: [Bytes.get_data(src) | struct.parts_reversed]}
      _ = %{struct | byte_length: struct.byte_length + length(src)}
    end
  end
  def add_string(struct, v, encoding) do
    src = Bytes.of_string(v, encoding)
    if (length(src) == 0) do
      nil
    else
      struct = %{struct | parts_reversed: [Bytes.get_data(src) | struct.parts_reversed]}
      _ = %{struct | byte_length: struct.byte_length + length(src)}
    end
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
    if (pos < 0 or len < 0 or pos + len > length(src)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      nil
    else
      slice = :binary.part(Bytes.get_data(src), pos, len)
      struct = %{struct | parts_reversed: [slice | struct.parts_reversed]}
      _ = %{struct | byte_length: struct.byte_length + len}
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
