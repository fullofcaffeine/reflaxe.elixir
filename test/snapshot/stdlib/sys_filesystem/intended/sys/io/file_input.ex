defmodule FileInput do
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
  def eof(struct) do
    result = :file.read(struct.device, 1)
    tag = case result do
            :eof -> :eof
            {t, _} -> t
        end
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
    tag = case result do
            :eof -> :eof
            {t, _} -> t
        end
    if (tag == :eof) do
      raise Reflaxe.Elixir.HaxeThrow, [value: %Eof{}]
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
    if (pos < 0 or len < 0 or pos + len > length(buf)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      result = :file.read(struct.device, len)
      tag = case result do
            :eof -> :eof
            {t, _} -> t
        end
      if (tag == :eof) do
        raise Reflaxe.Elixir.HaxeThrow, [value: %Eof{}]
      end
      if (tag == :ok) do
        data = elem(result, 1)
        bytes = Bytes.of_data(data)
        _ = Bytes.blit(buf, pos, bytes, 0, length(bytes))
        length(bytes)
      else
        reason = elem(result, 1)
        raise Reflaxe.Elixir.HaxeThrow, [value: "File read error: " <> inspect(reason)]
      end
    end
  end
  def close(struct) do
    :ok = File.close(struct.device)
  end
end
