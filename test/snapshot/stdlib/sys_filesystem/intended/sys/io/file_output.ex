defmodule Sys.IO.FileOutput do
  def new(device_param) do
    struct = %{:__reflaxe_class__ => Sys.IO.FileOutput, :device => nil, :big_endian => nil}
    struct = %{struct | device: device_param}
    struct
  end
  def seek(struct, p, pos) do
    (case pos do
      {:seek_begin} ->
        position(struct, {:bof, p})
      {:seek_cur} ->
        position(struct, {:cur, p})
      {:seek_end} ->
        position(struct, {:eof, p})
    end)
  end
  def tell(struct) do
    position(struct, :cur)
  end
  def write_byte(struct, c) do
    byte = Bytes.alloc(1)
    apply(Map.get(byte, :__reflaxe_class__) || Map.get(byte, :__struct__), :set, [byte, 0, c])
    write_data(struct, apply(Map.get(byte, :__reflaxe_class__) || Map.get(byte, :__struct__), :get_data, [byte]))
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > b.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      reflaxe_dispatch_receiver = apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :sub, [b, pos, len])
      slice = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver])
      write_data(struct, slice)
      len
    end
  end
  def close(struct) do
    result = File.close(struct.device)
    if (result != :ok) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "File close error"]
    end
  end
  defp position(struct, location) do
    result = :file.position(struct.device, location)
    if (elem(result, 0) != :ok), do: throw_file_error("position", result)
    elem(result, 1)
  end
  defp write_data(struct, data) do
    result = :file.write(struct.device, data)
    raw_result = result
    if (raw_result != :ok), do: throw_file_error("write", result)
  end
  defp throw_file_error(operation, result) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "File " <> operation <> " error: " <> List.to_string(:file.format_error(elem(result, 1)))]
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
