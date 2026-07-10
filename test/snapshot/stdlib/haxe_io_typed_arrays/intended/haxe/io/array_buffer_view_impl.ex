defmodule ArrayBufferViewImpl do
  def new(bytes_param, pos, length) do
    struct = %{:__reflaxe_class__ => ArrayBufferViewImpl, :bytes => nil, :byte_offset => nil, :byte_length => nil}
    struct = %{struct | bytes: bytes_param}
    struct = %{struct | byte_offset: pos}
    struct = %{struct | byte_length: length}
    struct
  end
end
