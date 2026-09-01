defmodule Reflaxe.Elixir.Runtime.StandardInput do
  def new() do
    %{:__reflaxe_class__ => Reflaxe.Elixir.Runtime.StandardInput, :big_endian => nil}
  end
  def read_byte(_struct) do
    reflaxe_dispatch_receiver = read_chunk(1)
    apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get, [reflaxe_dispatch_receiver, 0])
  end
  def read_bytes(_struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      bytes = read_chunk(len)
      apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :blit, [buf, pos, bytes, 0, bytes.length])
      bytes.length
    end
  end
  def read_line(_struct) do
    request = {:get_line, :unicode, ""}
    result = :io.request(:standard_io, request)
    if (result == :eof) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    if (not Kernel.is_binary(result)), do: throw_read_error(result)
    line = result
    line = if (StringTools.ends_with(line, "\n")) do
      StringTools.haxe_substr_non_nil_len(line, 0, (String.length(line) - 1))
    else
      line
    end
    line = if (StringTools.ends_with(line, "\r")) do
      StringTools.haxe_substr_non_nil_len(line, 0, (String.length(line) - 1))
    else
      line
    end
    line
  end
  def close(_struct) do

  end
  defp read_chunk(length) do
    request = {:get_chars, :latin1, "", length}
    result = :io.request(:standard_io, request)
    if (result == :eof) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    if (not Kernel.is_binary(result)), do: throw_read_error(result)
    Bytes.of_data(result)
  end
  defp throw_read_error(error) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Standard input read error: " <> List.to_string(:file.format_error(elem(error, 1)))]
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
