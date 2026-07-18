defmodule BytesOutput do
  def new() do
    struct = %{:__reflaxe_class__ => BytesOutput, :ref_id => nil, :dict_key => nil, :length => nil, :big_endian => nil}
    struct = %{struct | ref_id: :erlang.unique_integer([:positive])}
    struct = %{struct | dict_key: {:reflaxe_bytes_output, struct.ref_id}}
    state = %{parts_reversed: [], byte_length: 0}
    Process.put(struct.dict_key, state)
    struct
  end
  def get_length(struct) do
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{parts_reversed: [], byte_length: 0}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    state.byte_length
  end
  def write_byte(struct, c) do
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{parts_reversed: [], byte_length: 0}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    byte = Bitwise.band(c, 255)
    state = state |> Map.put(:parts_reversed, [byte | state.parts_reversed]) |> Map.put(:byte_length, state.byte_length + 1)
    Process.put(struct.dict_key, state)
  end
  def write_bytes(struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      slice = :binary.part(apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :get_data, [buf]), pos, len)
      state = Process.get(struct.dict_key)
      state = if (Kernel.is_nil(state)) do
        state = %{parts_reversed: [], byte_length: 0}
        Process.put(struct.dict_key, state)
        state
      else
        state
      end
      state = state |> Map.put(:parts_reversed, [slice | state.parts_reversed]) |> Map.put(:byte_length, state.byte_length + len)
      Process.put(struct.dict_key, state)
      len
    end
  end
  def write_input(struct, i, bufsize \\ nil) do
    bytes = apply(Map.get(i, :__reflaxe_class__) || Map.get(i, :__struct__), :read_all, [i, bufsize])
    if (bytes.length > 0) do
      apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_bytes, [struct, bytes, 0, bytes.length])
    end
  end
  def get_bytes(struct) do
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{parts_reversed: [], byte_length: 0}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    Process.delete(struct.dict_key)
    binary = :erlang.iolist_to_binary(:lists.reverse(state.parts_reversed))
    Bytes.of_data(binary)
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
  def write_string(struct, s, encoding) do
    Output.write_string(struct, s, encoding)
  end
end
