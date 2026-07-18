defmodule UInt8Array_Impl_ do
  def from_data(d) do
    d
  end
  def from_bytes(bytes, byte_pos \\ 0, length \\ nil) do
    from_data(ArrayBufferView_Impl_.from_bytes(bytes, byte_pos, length))
  end
end
