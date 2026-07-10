defmodule Bytes do
  defp new(length_param, b_param) do
    struct = %{:__reflaxe_class__ => Bytes, :length => nil, :b => nil, :ref_id => nil, :dict_key => nil}
    struct = %{struct | length: length_param}
    struct = %{struct | ref_id: :erlang.unique_integer([:positive])}
    struct = %{struct | dict_key: {:reflaxe_bytes, struct.ref_id}}
    struct = %{struct | b: b_param}
    Process.put(struct.dict_key, b_param)
    struct
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
  def get_float(struct, pos) do
    if (pos < 0 or pos + 4 > struct.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Out of bounds"]
    end
    _ =
      Reflaxe.Elixir.HaxeFloat.decode32((fn -> :binary.part((fn -> data = Process.get(struct.dict_key)
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
  def alloc(length_param) do
    b = :binary.copy(<<0>>, length_param)
    _ = new(length_param, b)
  end
end
