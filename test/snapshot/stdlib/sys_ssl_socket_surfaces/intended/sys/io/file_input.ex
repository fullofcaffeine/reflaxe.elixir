defmodule Sys.IO.FileInput do
  def new(device_param) do
    struct = %{:__reflaxe_class__ => Sys.IO.FileInput, :device => nil, :big_endian => nil}
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
  def eof(struct) do
    result = :file.read(struct.device, 1)
    if (Reflaxe.Elixir.HaxeFloat.eq(result, :eof)) do
      true
    else
      data = read_data(result)
      position(struct, {:cur, -data.length})
      false
    end
  end
  def read_byte(struct) do
    result = :file.read(struct.device, 1)
    if (Reflaxe.Elixir.HaxeFloat.eq(result, :eof)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    reflaxe_dispatch_receiver = read_data(result)
    apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get, [reflaxe_dispatch_receiver, 0])
  end
  def read_bytes(struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      result = :file.read(struct.device, len)
      if (Reflaxe.Elixir.HaxeFloat.eq(result, :eof)) do
        raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
      end
      bytes = read_data(result)
      apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :blit, [buf, pos, bytes, 0, bytes.length])
      bytes.length
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
  defp read_data(result) do
    tagged = result
    if (elem(tagged, 0) != :ok), do: throw_file_error("read", tagged)
    Bytes.of_data(elem(tagged, 1))
  end
  defp throw_file_error(operation, result) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "File " <> operation <> " error: " <> :file.format_error(elem(result, 1))]
  end
  def set_big_endian(struct, b) do
    Input.set_big_endian(struct, b)
  end
  def read_all(struct, bufsize) do
    Input.read_all(struct, bufsize)
  end
  def read_full_bytes(struct, s, pos, len) do
    Input.read_full_bytes(struct, s, pos, len)
  end
  def read(struct, nbytes) do
    Input.read(struct, nbytes)
  end
  def read_until(struct, end_param) do
    Input.read_until(struct, end_param)
  end
  def read_line(struct) do
    Input.read_line(struct)
  end
  def read_float(struct) do
    Input.read_float(struct)
  end
  def read_double(struct) do
    Input.read_double(struct)
  end
  def read_int8(struct) do
    Input.read_int8(struct)
  end
  def read_int16(struct) do
    Input.read_int16(struct)
  end
  def read_u_int16(struct) do
    Input.read_u_int16(struct)
  end
  def read_int24(struct) do
    Input.read_int24(struct)
  end
  def read_u_int24(struct) do
    Input.read_u_int24(struct)
  end
  def read_int32(struct) do
    Input.read_int32(struct)
  end
  def read_string(struct, len, encoding) do
    Input.read_string(struct, len, encoding)
  end
end
