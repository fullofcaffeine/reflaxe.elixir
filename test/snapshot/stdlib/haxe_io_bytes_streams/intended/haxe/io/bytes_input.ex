defmodule BytesInput do
  def new(bytes, pos_param, len) do
    struct = %{:data => nil, :pos => nil, :remaining => nil, :total_length => nil, :position => nil, :length => nil}
    pos_param = if (Kernel.is_nil(pos_param)) do
      
    else
      pos_param
    end
    len = if (Kernel.is_nil(len)), do: (length(bytes) - pos_param), else: len
    if (pos_param < 0 or len < 0 or pos_param + len > length(bytes)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    struct = %{struct | data: :binary.part(Bytes.get_data(bytes), pos_param, len)}
    struct = %{struct | pos: 0}
    struct = %{struct | remaining: len}
    struct = %{struct | total_length: len}
    struct
  end
  def read_byte(struct) do
    if (struct.remaining == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    struct = %{struct | remaining: (struct.remaining - 1)}
    struct = %{struct | pos: struct.pos + 1}
    :binary.at(struct.data, struct.pos)
  end
  def read_bytes(struct, buf, pos_param, len) do
    if (pos_param < 0 or len < 0 or pos_param + len > length(buf)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      if (struct.remaining == 0) do
        raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
      end
      len = if (len > struct.remaining), do: struct.remaining, else: len
      slice = :binary.part(struct.data, struct.pos, len)
      src = Bytes.of_data(slice)
      _ = Bytes.blit(buf, pos_param, src, 0, len)
      struct = %{struct | pos: struct.pos + len}
      _ = %{struct | remaining: (struct.remaining - len)}
      len
    end
  end
end
