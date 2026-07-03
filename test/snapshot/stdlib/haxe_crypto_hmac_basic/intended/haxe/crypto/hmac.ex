defmodule Haxe.Crypto.Hmac do
  def new(hash_method) do
    struct = %{:__reflaxe_class__ => Haxe.Crypto.Hmac, :method => nil}
    struct = %{struct | method: hash_method}
    struct
  end
  def make(struct, key, msg) do
    digest = :crypto.mac(:hmac, native_algorithm(struct), apply(Map.get(key, :__reflaxe_class__) || Map.get(key, :__struct__), :get_data, [key]), apply(Map.get(msg, :__reflaxe_class__) || Map.get(msg, :__struct__), :get_data, [msg]))
    _ = Bytes.of_data(digest)
  end
  defp native_algorithm(struct) do
    (case struct.method do
      {:md5} -> :md5
      {:sha1} -> :sha
      {:sha256} -> :sha256
    end)
  end
end
