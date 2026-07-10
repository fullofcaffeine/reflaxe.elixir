defmodule ArrayBufferView_Impl_ do
  def from_bytes(bytes, pos, length) do
    length = if (Kernel.is_nil(length)), do: (bytes.length - pos), else: length
    if (pos < 0 or length < 0 or pos + length > bytes.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    a = ArrayBufferViewImpl.new(bytes, pos, length)
    a
  end
end
