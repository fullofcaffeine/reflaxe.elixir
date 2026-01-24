defmodule BytesInput do
  def new(bytes, pos, len) do
    struct = %{:__reflaxe_class__ => BytesInput, :data => nil, :total_length => nil, :ref_id => nil, :dict_key => nil, :position => nil, :length => nil, :big_endian => nil}
    pos = if (Kernel.is_nil(pos)), do: 0, else: pos
    len = if (Kernel.is_nil(len)), do: (bytes.length - pos), else: len
    if (pos < 0 or len < 0 or pos + len > bytes.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    struct = %{struct | data: :binary.part(apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes]), pos, len)}
    struct = %{struct | total_length: len}
    struct = %{struct | ref_id: :erlang.unique_integer([:positive])}
    struct = %{struct | dict_key: {:reflaxe_bytes_input, struct.ref_id}}
    Process.put(struct.dict_key, %{:pos => 0, :remaining => len})
    struct
  end
  def get_position(struct) do
    state = Process.get(struct.dict_key)
state = if (Kernel.is_nil(state)) do
  state = %{:pos => 0, :remaining => struct.total_length}
  Process.put(struct.dict_key, state)
  state
else
  state
end
state.pos
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
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{:pos => 0, :remaining => struct.total_length}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    state = state |> Map.put(:remaining, (struct.total_length - p)) |> Map.put(:pos, p)
    Process.put(struct.dict_key, state)
    state.pos
  end
  def read_byte(struct) do
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{:pos => 0, :remaining => struct.total_length}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    if (state.remaining == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    current_pos = state.pos
    state = state |> Map.put(:remaining, (state.remaining - 1)) |> Map.put(:pos, current_pos + 1)
    Process.put(struct.dict_key, state)
    :binary.at(struct.data, current_pos)
  end
  def read_bytes(struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      state = Process.get(struct.dict_key)
      state = if (Kernel.is_nil(state)) do
        state = %{:pos => 0, :remaining => struct.total_length}
        Process.put(struct.dict_key, state)
        state
      else
        state
      end
      if (state.remaining == 0) do
        raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
      end
      len = if (len > state.remaining), do: state.remaining, else: len
      slice = :binary.part(struct.data, state.pos, len)
      src = Bytes.of_data(slice)
      _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :blit, [buf, pos, src, 0, len])
      state = state |> Map.put(:pos, state.pos + len) |> Map.put(:remaining, (state.remaining - len))
      Process.put(struct.dict_key, state)
      len
    end
  end
  def read_all(struct, _) do
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{:pos => 0, :remaining => struct.total_length}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    if (state.remaining == 0) do
      Bytes.alloc(0)
    else
      slice = :binary.part(struct.data, state.pos, state.remaining)
      state = state |> Map.put(:pos, state.pos + state.remaining) |> Map.put(:remaining, 0)
      Process.put(struct.dict_key, state)
      _ = Bytes.of_data(slice)
    end
  end
  def read_line(struct) do
    state = Process.get(struct.dict_key)
    state = if (Kernel.is_nil(state)) do
      state = %{:pos => 0, :remaining => struct.total_length}
      Process.put(struct.dict_key, state)
      state
    else
      state
    end
    if (state.remaining == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    result = (fn ->
  rem = :binary.part(struct.data, state.pos, state.remaining)
  case :binary.match(rem, "\n") do
    :nomatch -> {rem, byte_size(rem)}
    {idx, _} ->
      line_len = if idx > 0 and :binary.at(rem, idx - 1) == 13, do: idx - 1, else: idx
      {:binary.part(rem, 0, line_len), idx + 1}
  end
end).()
    line = elem(result, 0)
    advance = elem(result, 1)
    state = state |> Map.put(:pos, state.pos + advance) |> Map.put(:remaining, (state.remaining - advance))
    Process.put(struct.dict_key, state)
    line
  end
  def close(struct) do
    Process.delete(struct.dict_key)
  end
  def set_big_endian(struct, b) do
    Input.set_big_endian(struct, b)
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
