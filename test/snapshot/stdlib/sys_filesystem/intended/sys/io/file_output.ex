defmodule FileOutput do
  def new(device_param) do
    struct = %{:device => nil}
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
  def write_byte(struct, c) do
    :ok = :file.write(struct.device, <<c::8>>)
  end
  def write_bytes(struct, b, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(b)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      slice = Bytes.get_data(Bytes.sub(b, pos, len))
      :ok = :file.write(struct.device, slice)
      len
    end
  end
  def close(struct) do
    :ok = File.close(struct.device)
  end
end
