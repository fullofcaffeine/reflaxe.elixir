defmodule Haxe.Crypto.Crc32 do
  def new() do
    struct = %{:__reflaxe_class__ => Haxe.Crypto.Crc32, :crc => nil}
    struct = %{struct | crc: 0}
    struct
  end
  def byte(struct, b) do
    byte_value = :erlang.band(b, 255)
    updated = (:erlang.crc32((fn -> value = struct.crc
if value < 0, do: value + 4294967296, else: value end).(), <<byte_value::unsigned-size(8)>>))
    struct = %{struct | crc: (if :erlang.band(updated, 4294967295) >= 2147483648, do: :erlang.band(updated, 4294967295) - 4294967296, else: :erlang.band(updated, 4294967295))}
    struct
  end
  def update(struct, b, pos, len) do
    if (len != 0) do
      slice = :binary.part(apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :get_data, [b]), pos, len)
      updated = (:erlang.crc32((fn -> value = struct.crc
if value < 0, do: value + 4294967296, else: value end).(), slice))
      struct = %{struct | crc: (if :erlang.band(updated, 4294967295) >= 2147483648, do: :erlang.band(updated, 4294967295) - 4294967296, else: :erlang.band(updated, 4294967295))}
      struct
    else
      struct
    end
  end
  def get(struct) do
    struct.crc
  end
  def make(data) do
    value = :erlang.crc32(apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_data, [data]))
    (if :erlang.band(value, 4294967295) >= 2147483648, do: :erlang.band(value, 4294967295) - 4294967296, else: :erlang.band(value, 4294967295))
  end
end
