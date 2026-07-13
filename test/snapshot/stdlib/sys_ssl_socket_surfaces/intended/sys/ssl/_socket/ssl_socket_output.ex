defmodule SslSocketOutput do
  def new(socket_ref_param) do
    struct = %{:__reflaxe_class__ => SslSocketOutput, :socket_ref => nil, :big_endian => nil}
    struct = %{struct | socket_ref: socket_ref_param}
    struct
  end
  def write_byte(struct, c) do
    SslSocketState.send_binary(struct.socket_ref, <<c::8>>)
  end
  def write_bytes(struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      SslSocketState.send_binary(struct.socket_ref, (fn ->
        reflaxe_dispatch_receiver = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :sub, [buf, pos, len])
        apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver])
      end).())
      len
    end
  end
  def set_big_endian(struct, b) do
    Output.set_big_endian(struct, b)
  end
  def flush(struct) do
    Output.flush(struct)
  end
  def close(struct) do
    Output.close(struct)
  end
  def write(struct, s) do
    Output.write(struct, s)
  end
  def write_full_bytes(struct, s, pos, len) do
    Output.write_full_bytes(struct, s, pos, len)
  end
  def write_float(struct, x) do
    Output.write_float(struct, x)
  end
  def write_double(struct, x) do
    Output.write_double(struct, x)
  end
  def write_int8(struct, x) do
    Output.write_int8(struct, x)
  end
  def write_int16(struct, x) do
    Output.write_int16(struct, x)
  end
  def write_u_int16(struct, x) do
    Output.write_u_int16(struct, x)
  end
  def write_int24(struct, x) do
    Output.write_int24(struct, x)
  end
  def write_u_int24(struct, x) do
    Output.write_u_int24(struct, x)
  end
  def write_int32(struct, x) do
    Output.write_int32(struct, x)
  end
  def prepare(struct, nbytes) do
    Output.prepare(struct, nbytes)
  end
  def write_input(struct, i, bufsize) do
    Output.write_input(struct, i, bufsize)
  end
  def write_string(struct, s, encoding) do
    Output.write_string(struct, s, encoding)
  end
end
