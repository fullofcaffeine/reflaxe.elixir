defmodule Haxe.Crypto.Adler32 do
  import Kernel, except: [to_string: 1], warn: false
  def new() do
    struct = %{:__reflaxe_class__ => Haxe.Crypto.Adler32, :adler => nil}
    struct = %{struct | adler: 1}
    struct
  end
  def get(struct) do
    struct.adler
  end
  def update(struct, b, pos, len) do
    if (len != 0) do
      slice = :binary.part(apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :get_data, [b]), pos, len)
      updated = (:erlang.adler32((fn -> value = struct.adler
if value < 0, do: value + 4294967296, else: value end).(), slice))
      struct = %{struct | adler: (if :erlang.band(updated, 4294967295) >= 2147483648, do: :erlang.band(updated, 4294967295) - 4294967296, else: :erlang.band(updated, 4294967295))}
      struct
    else
      struct
    end
  end
  def equals(struct, a) do
    a.adler == struct.adler
  end
  def to_string(struct) do
    value = struct.adler
    unsigned = if value < 0, do: value + 4294967296, else: value
    a1 = :erlang.band(unsigned, 65535)
    a2 = :erlang.bsr(unsigned, 16)
    "#{StringTools.hex(a2, 8)}#{StringTools.hex(a1, 8)}"
  end
  def read(i) do
    a = Haxe.Crypto.Adler32.new()
    a2a = apply(Map.get(i, :__reflaxe_class__) || Map.get(i, :__struct__), :read_byte, [i])
    a2b = apply(Map.get(i, :__reflaxe_class__) || Map.get(i, :__struct__), :read_byte, [i])
    a1a = apply(Map.get(i, :__reflaxe_class__) || Map.get(i, :__struct__), :read_byte, [i])
    a1b = apply(Map.get(i, :__reflaxe_class__) || Map.get(i, :__struct__), :read_byte, [i])
    a = %{a | adler: (if :erlang.band(Bitwise.bor(Bitwise.bor(Bitwise.bor(Bitwise.bsl(a2a, 24), Bitwise.bsl(a2b, 16)), Bitwise.bsl(a1a, 8)), a1b), 4294967295) >= 2147483648, do: :erlang.band(Bitwise.bor(Bitwise.bor(Bitwise.bor(Bitwise.bsl(a2a, 24), Bitwise.bsl(a2b, 16)), Bitwise.bsl(a1a, 8)), a1b), 4294967295) - 4294967296, else: :erlang.band(Bitwise.bor(Bitwise.bor(Bitwise.bor(Bitwise.bsl(a2a, 24), Bitwise.bsl(a2b, 16)), Bitwise.bsl(a1a, 8)), a1b), 4294967295))}
    a
  end
  def make(b) do
    value = :erlang.adler32(apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :get_data, [b]))
    (if :erlang.band(value, 4294967295) >= 2147483648, do: :erlang.band(value, 4294967295) - 4294967296, else: :erlang.band(value, 4294967295))
  end
end
