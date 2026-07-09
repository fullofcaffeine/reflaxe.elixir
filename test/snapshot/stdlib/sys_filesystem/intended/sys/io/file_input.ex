defmodule FileInput do
  def new(device_param) do
    struct = %{:__reflaxe_class__ => FileInput, :device => nil, :big_endian => nil}
    struct = %{struct | device: device_param}
    struct
  end
  def seek(struct, p, pos) do
    (case pos do
      {:seek_begin} -> {:ok, _} = :file.position(struct.device, {:bof, p})
      {:seek_cur} -> {:ok, _} = :file.position(struct.device, {:cur, p})
      {:seek_end} -> {:ok, _} = :file.position(struct.device, {:eof, p})
    end)
  end
  def tell(struct) do
    case :file.position(struct.device, :cur) do {:ok, p} -> p end
  end
  def eof(struct) do
    result = :file.read(struct.device, 1)
    tag = (case result do
                :eof -> :eof
                {t, _} -> t
            end)
    if (tag == :eof) do
      true
    else
      if (tag == :ok) do
        data = elem(result, 1)
        {:ok, _} = :file.position(struct.device, {:cur, -byte_size(data)})
        false
      else
        reason = elem(result, 1)
        raise Reflaxe.Elixir.HaxeThrow, [value: "File read error: " <> inspect(reason)]
      end
    end
  end
  def read_byte(struct) do
    result = :file.read(struct.device, 1)
    tag = (case result do
                :eof -> :eof
                {t, _} -> t
            end)
    if (tag == :eof) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    if (tag == :ok) do
      data = elem(result, 1)
      :binary.at(data, 0)
    else
      reason = elem(result, 1)
      raise Reflaxe.Elixir.HaxeThrow, [value: "File read error: " <> inspect(reason)]
    end
  end
  def read_bytes(struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      result = :file.read(struct.device, len)
      tag = (case result do
                  :eof -> :eof
                  {t, _} -> t
              end)
      if (tag == :eof) do
        raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
      end
      if (tag == :ok) do
        data = elem(result, 1)
        bytes = Bytes.of_data(data)
        _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :blit, [buf, pos, bytes, 0, bytes.length])
        bytes.length
      else
        reason = elem(result, 1)
        raise Reflaxe.Elixir.HaxeThrow, [value: "File read error: " <> inspect(reason)]
      end
    end
  end
  def close(struct) do
    :ok = File.close(struct.device)
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
