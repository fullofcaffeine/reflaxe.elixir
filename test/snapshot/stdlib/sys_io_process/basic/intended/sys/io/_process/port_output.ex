defmodule PortOutput do
  def new(port_param) do
    struct = %{:port => nil}
    struct = %{struct | port: port_param}
    struct
  end
  def write_byte(struct, c) do
    Port.command(struct.port, <<c::8>>)
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      slice = Bytes.get_data(Bytes.sub(b, pos, len))
      Port.command(struct.port, slice)
      len
    end
  end
  def close(_) do
    
  end
end
