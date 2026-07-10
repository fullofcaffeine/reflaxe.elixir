defmodule Main do
  def main() do
    floats = (fn ->
      size = 8
      _ = ArrayBufferViewImpl.new(Bytes.alloc(size), 0, size)
    end).()
    if (0 < Bitwise.bsr(floats.byte_length, 2)) do
      reflaxe_dispatch_receiver = floats.bytes
      _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :set_float, [reflaxe_dispatch_receiver, floats.byte_offset, 1.25])
      1.25
    else
      0
    end
    if (Reflaxe.Elixir.HaxeFloat.neq((fn ->
      reflaxe_dispatch_receiver = floats.bytes
      _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_float, [reflaxe_dispatch_receiver, floats.byte_offset])
    end).(), 1.25)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Float32Array write failed"]
    end
    bytes = Bytes.alloc(2)
    octets = UInt8Array_Impl_.from_bytes(bytes, 0, nil)
    if (0 < octets.byte_length) do
      reflaxe_dispatch_receiver = octets.bytes
      _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :set, [reflaxe_dispatch_receiver, octets.byte_offset, 55])
      55
    else
      0
    end
    if (apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get, [bytes, 0]) != 55) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "UInt8Array shared write failed"]
    end
  end
end
