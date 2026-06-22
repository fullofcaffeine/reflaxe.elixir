defmodule Bytes do
  import Kernel, except: [to_string: 1], warn: false
  defp new(length_param, b_param) do
    struct = %{:__reflaxe_class__ => Bytes, :length => nil, :b => nil, :ref_id => nil, :dict_key => nil}
    struct = %{struct | length: length_param}
    struct = %{struct | ref_id: :erlang.unique_integer([:positive])}
    struct = %{struct | dict_key: {:reflaxe_bytes, struct.ref_id}}
    struct = %{struct | b: b_param}
    Process.put(struct.dict_key, b_param)
    struct
  end
  def get_string(struct, pos, len, _encoding) do
    if (pos < 0 or len < 0 or pos + len > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    slice = :binary.part(data, pos, len)
    :unicode.characters_to_binary(slice, :utf8)
  end
  def to_string(struct) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :get_string, [struct, 0, struct.length, nil])
  end
  def get(struct, pos) do
    if (pos < 0 or pos >= struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    :binary.at((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos)
  end
  def set(struct, pos, v) do
    if (pos < 0 or pos >= struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos < (struct.length - 1)) do
      :binary.part(data, pos + 1, ((struct.length - pos) - 1))
    else
      <<>>
    end
    data = <<before_part::binary, v::8, after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def blit(struct, pos, src, srcpos, len) do
    if (pos < 0 or srcpos < 0 or len < 0 or pos + len > struct.length or srcpos + len > src.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    src_slice = :binary.part(apply(Map.get(src, :__reflaxe_class__) || Map.get(src, :__struct__), :get_data, [src]), srcpos, len)
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + len < struct.length) do
      :binary.part(data, pos + len, ((struct.length - pos) - len))
    else
      <<>>
    end
    data = <<before_part::binary, src_slice::binary, after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def sub(struct, pos, len) do
    if (pos < 0 or len < 0 or pos + len > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    sub_binary = (:binary.part((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos, len))
    _ = new(len, sub_binary)
  end
  def fill(struct, pos, len, value) do
    if (pos < 0 or len < 0 or pos + len > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    fill_bytes = :binary.copy(<<value::8>>, len)
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + len < struct.length) do
      :binary.part(data, pos + len, ((struct.length - pos) - len))
    else
      <<>>
    end
    data = <<before_part::binary, fill_bytes::binary, after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def compare(struct, other) do
    cond do
                (fn -> data = Process.get(struct.dict_key)
    if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
    end
    data end).() < apply(Map.get(other, :__reflaxe_class__) || Map.get(other, :__struct__), :get_data, [other]) -> -1
                (fn -> data = Process.get(struct.dict_key)
    if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
    end
    data end).() > apply(Map.get(other, :__reflaxe_class__) || Map.get(other, :__struct__), :get_data, [other]) -> 1
                true -> 0
            end
  end
  def get_data(struct) do
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    data
  end
  def get_double(struct, pos) do
    if (pos < 0 or pos + 8 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    _ = Reflaxe.Elixir.HaxeFloat.decode64((fn -> :binary.part((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos, 8) end).())
  end
  def set_double(struct, pos, v) do
    if (pos < 0 or pos + 8 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 8 < struct.length) do
      :binary.part(data, pos + 8, ((struct.length - pos) - 8))
    else
      <<>>
    end
    encoded = Reflaxe.Elixir.HaxeFloat.encode64(v)
    data = <<before_part::binary, encoded::binary, after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def get_float(struct, pos) do
    if (pos < 0 or pos + 4 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    _ = Reflaxe.Elixir.HaxeFloat.decode32((fn -> :binary.part((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos, 4) end).())
  end
  def set_float(struct, pos, v) do
    if (pos < 0 or pos + 4 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 4 < struct.length) do
      :binary.part(data, pos + 4, ((struct.length - pos) - 4))
    else
      <<>>
    end
    encoded = Reflaxe.Elixir.HaxeFloat.encode32(v)
    data = <<before_part::binary, encoded::binary, after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def get_u_int16(struct, pos) do
    if (pos < 0 or pos + 2 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    <<value::little-unsigned-size(16)>> = :binary.part((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos, 2); value
  end
  def set_u_int16(struct, pos, v) do
    if (pos < 0 or pos + 2 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 2 < struct.length) do
      :binary.part(data, pos + 2, ((struct.length - pos) - 2))
    else
      <<>>
    end
    data = <<before_part::binary, v::little-unsigned-size(16), after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def get_int32(struct, pos) do
    if (pos < 0 or pos + 4 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    <<value::little-signed-size(32)>> = :binary.part((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos, 4); value
  end
  def set_int32(struct, pos, v) do
    if (pos < 0 or pos + 4 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 4 < struct.length) do
      :binary.part(data, pos + 4, ((struct.length - pos) - 4))
    else
      <<>>
    end
    data = <<before_part::binary, v::little-signed-size(32), after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def get_int64(struct, pos) do
    if (pos < 0 or pos + 8 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    <<value::little-signed-size(64)>> = :binary.part((fn -> data = Process.get(struct.dict_key)
if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
  data = struct.b
  Process.put(struct.dict_key, data)
end
data end).(), pos, 8); value
  end
  def set_int64(struct, pos, v) do
    if (pos < 0 or pos + 8 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    data = Process.get(struct.dict_key)
    data = if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
      data
    else
      data
    end
    before_part = if (pos > 0) do
      :binary.part(data, 0, pos)
    else
      <<>>
    end
    after_part = if (pos + 8 < struct.length) do
      :binary.part(data, pos + 8, ((struct.length - pos) - 8))
    else
      <<>>
    end
    data = <<before_part::binary, v::little-signed-size(64), after_part::binary>>
    struct = %{struct | b: data}
    Process.put(struct.dict_key, data)
  end
  def read_string(struct, pos, len) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :get_string, [struct, pos, len, nil])
  end
  def to_hex(struct) do
    Base.encode16((fn -> data = Process.get(struct.dict_key)
    if (Reflaxe.Elixir.HaxeFloat.eq(data, nil)) do
      data = struct.b
      Process.put(struct.dict_key, data)
    end
    data end).(), case: :lower)
  end
  def alloc(length_param) do
    b = :binary.copy(<<0>>, length_param)
    _ = new(length_param, b)
  end
  def of_string(s, _encoding) do
    binary = :unicode.characters_to_binary(s, :utf8)
    length = byte_size(binary)
    _ = new(length, binary)
  end
  def fast_get(b_param, pos) do
    :binary.at(b_param, pos)
  end
  def of_hex(s) do
    binary = Base.decode16!(s, case: :mixed)
    length = byte_size(binary)
    _ = new(length, binary)
  end
  def of_data(b_param) do
    length = byte_size(b_param)
    _ = new(length, b_param)
  end
end
