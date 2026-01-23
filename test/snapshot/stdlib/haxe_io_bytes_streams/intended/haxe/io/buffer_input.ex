defmodule BufferInput do
  def new(i_param, buf_param, pos_param, available_param) do
    struct = %{:i => nil, :buf => nil, :available => nil, :pos => nil}
    struct = %{struct | i: i_param}
    struct = %{struct | buf: buf_param}
    struct = %{struct | pos: pos_param}
    struct = %{struct | available: available_param}
    struct
  end
  def refill(struct) do
    if (struct.pos > 0) do
      _ = Bytes.blit(struct.buf, 0, struct.buf, struct.pos, struct.available)
      _ = %{struct | pos: 0}
    end
    struct = %{struct | available: struct.available + Input.read_bytes(struct.i, struct.buf, struct.available, (length(struct.buf) - struct.available))}
    struct
  end
  def read_byte(struct) do
    if (struct.available == 0), do: refill(struct)
    struct = %{struct | pos: struct.pos + 1}
    struct = %{struct | available: (struct.available - 1)}
    Bytes.get(struct.buf, struct.pos)
  end
  def read_bytes(struct, buf_param, pos_param, len) do
    if (struct.available == 0), do: refill(struct)
    size = if (len > struct.available), do: struct.available, else: len
    _ = Bytes.blit(buf_param, pos_param, struct.buf, struct.pos, size)
    struct = %{struct | pos: struct.pos + size}
    _ = %{struct | available: (struct.available - size)}
    size
  end
end
