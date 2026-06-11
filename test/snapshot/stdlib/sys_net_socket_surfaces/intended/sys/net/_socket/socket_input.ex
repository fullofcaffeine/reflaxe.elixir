defmodule SocketInput do
  def new(socket_ref_param) do
    struct = %{:__reflaxe_class__ => SocketInput, :socket_ref => nil, :big_endian => nil}
    struct = %{struct | socket_ref: socket_ref_param}
    struct
  end
  def read_byte(struct) do
    result = SocketState.recv_binary(struct.socket_ref, 1)
    if (SocketState.is_blocked(result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
    end
    if (SocketState.is_eof(result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    if (SocketState.is_error(result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, SocketState.error_message(result)}]
    end
    :binary.at(result, 0)
  end
  def read_bytes(_struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.net.Socket.input.readBytes is not supported on the Elixir target because haxe.io.Bytes buffers are immutable in generated Elixir; use Socket.read() or Input.readByte() instead"}]
    end
  end
  def set_big_endian(struct, b) do
    Input.set_big_endian(struct, b)
  end
  def close(struct) do
    Input.close(struct)
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
