defmodule Key do
  defp new(key_ref_param) do
    struct = %{:__reflaxe_class__ => Key, :key_ref => nil}
    struct = %{struct | key_ref: key_ref_param}
    struct
  end
  def to_ssl_key(struct) do
    struct.key_ref
  end
  def load_file(file, is_public \\ nil, pass \\ nil) do
    data = Sys.IO.File.get_bytes(file)
    if (data.length >= 11 and apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_string, [data, 0, 11, nil]) == "-----BEGIN ") do
      read_pem(apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :to_string, [data]), is_public == true, pass)
    else
      read_der(data, is_public == true)
    end
  end
  def read_pem(data, is_public, pass \\ nil) do
    new(KeyState.read_pem(data, is_public, pass))
  end
  def read_der(data, is_public) do
    new(KeyState.read_der(apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_data, [data]), is_public))
  end
end
