defmodule Sys.IO.File do
  def get_content(path) do
    File.read!(path)
  end
  def save_content(path, content) do
    File.write!(path, content)
  end
  def get_bytes(path) do
    data = File.read!(path)
    Bytes.of_data(data)
  end
  def save_bytes(path, bytes) do
    File.write!(path, apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes]))
  end
  def read(path, binary \\ true) do
    modes = if (binary), do: [:read, :binary], else: [:read]
    device = File.open!(path, modes)
    Sys.IO.FileInput.new(device)
  end
  def write(path, binary \\ true) do
    modes = if (binary), do: [:write, :binary], else: [:write]
    device = File.open!(path, modes)
    Sys.IO.FileOutput.new(device)
  end
  def append(path, binary \\ true) do
    modes = if (binary), do: [:append, :binary], else: [:append]
    device = File.open!(path, modes)
    Sys.IO.FileOutput.new(device)
  end
  def update(path, binary \\ true) do
    modes = if (binary), do: [:read, :write, :binary], else: [:read, :write]
    device = File.open!(path, modes)
    Sys.IO.FileOutput.new(device)
  end
  def copy(src_path, dst_path) do
    File.cp!(src_path, dst_path)
  end
end
