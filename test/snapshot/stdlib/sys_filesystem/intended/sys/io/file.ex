defmodule File do
  def get_content(path) do
    read!(path)
  end
  def save_content(path, content) do
    write!(path, content)
  end
  def get_bytes(path) do
    data = read!(path)
    _ = Bytes.of_data(data)
  end
  def save_bytes(path, bytes) do
    write!(path, Bytes.get_data(bytes))
  end
  def read(path, binary) do
    device = open_bang(path, (if (binary), do: ["read", "binary"], else: ["read"]))
    _ = FileInput.new(device)
  end
  def write(path, binary) do
    device = open_bang(path, (if (binary), do: ["write", "binary"], else: ["write"]))
    _ = FileOutput.new(device)
  end
  def append(path, binary) do
    device = open_bang(path, (if (binary), do: ["append", "binary"], else: ["append"]))
    _ = FileOutput.new(device)
  end
  def update(path, binary) do
    device = open_bang(path, (if (binary), do: ["read", "write", "binary"], else: ["read", "write"]))
    _ = FileOutput.new(device)
  end
  def copy(src_path, dst_path) do
    cp!(src_path, dst_path)
  end
  defp open_bang(path, modes) do
    
            atom_modes =
              Enum.map(modes, fn
                "read" -> :read
                "write" -> :write
                "append" -> :append
                "binary" -> :binary
                other -> String.to_atom(other)
              end)
            File.open!(path, atom_modes)
        
  end
end
