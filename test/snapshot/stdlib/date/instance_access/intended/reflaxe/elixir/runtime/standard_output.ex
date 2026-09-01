defmodule Reflaxe.Elixir.Runtime.StandardOutput do
  def new(device_param) do
    struct = %{:__reflaxe_class__ => Reflaxe.Elixir.Runtime.StandardOutput, :device => nil, :big_endian => nil}
    struct = %{struct | device: device_param}
    struct
  end
  def write_byte(struct, c) do
    byte = Bytes.alloc(1)
    apply(Map.get(byte, :__reflaxe_class__) || Map.get(byte, :__struct__), :set, [byte, 0, c])
    write_data(struct, apply(Map.get(byte, :__reflaxe_class__) || Map.get(byte, :__struct__), :get_data, [byte]))
  end
  def write_bytes(struct, bytes, pos, len) do
    if (pos < 0 or len < 0 or pos + len > bytes.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      write_data(
        struct,
        (fn ->
           reflaxe_dispatch_receiver = apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :sub, [bytes, pos, len])
           apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver])
         end).()
      )
      len
    end
  end
  def close(_struct) do

  end
  defp write_data(struct, data) do
    result = IO.binwrite(struct.device, data)
    if (result != :ok) do
      error = result
      raise Reflaxe.Elixir.HaxeThrow, [value: "Standard output write error: " <> List.to_string(:file.format_error(elem(error, 1)))]
    end
  end
  def set_big_endian(struct, b) do
    Output.set_big_endian(struct, b)
  end
  def flush(struct) do
    Output.flush(struct)
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
