defmodule BufferInput do
  def new(i_param, buf_param, pos_param \\ 0, available_param \\ 0) do
    struct = %{:__reflaxe_class__ => BufferInput, :i => nil, :buf => nil, :available => nil, :pos => nil, :big_endian => nil}
    struct = %{struct | i: i_param}
    struct = %{struct | buf: buf_param}
    struct = %{struct | pos: pos_param}
    struct = %{struct | available: available_param}
    struct
  end
  def refill(struct) do
    struct = if (struct.pos > 0) do
      reflaxe_dispatch_receiver_node_0 = struct.buf
      apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :blit, [reflaxe_dispatch_receiver_node_0, 0, struct.buf, struct.pos, struct.available])
      %{struct | pos: 0}
    else
      struct
    end
    struct = %{struct | available: struct.available + (fn ->
      reflaxe_dispatch_receiver_node_1 = struct.i
      apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :read_bytes, [reflaxe_dispatch_receiver_node_1, struct.buf, struct.available, (struct.buf.length - struct.available)])
    end).()}
    struct
  end
  def read_byte(struct) do
    if (struct.available == 0) do
      apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :refill, [struct])
    end
    struct = %{struct | pos: struct.pos + 1}
    struct = %{struct | available: (struct.available - 1)}
    reflaxe_dispatch_receiver_node_2 = struct.buf
    apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :get, [reflaxe_dispatch_receiver_node_2, struct.pos])
  end
  def read_bytes(struct, buf_param, pos_param, len) do
    if (struct.available == 0) do
      apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :refill, [struct])
    end
    size = if (len > struct.available), do: struct.available, else: len
    apply(Map.get(buf_param, :__reflaxe_class__) || Map.get(buf_param, :__struct__), :blit, [buf_param, pos_param, struct.buf, struct.pos, size])
    struct = %{struct | pos: struct.pos + size}
    _ = %{struct | available: (struct.available - size)}
    size
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
