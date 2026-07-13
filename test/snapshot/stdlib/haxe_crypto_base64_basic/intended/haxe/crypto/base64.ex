defmodule Haxe.Crypto.Base64 do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Haxe.Crypto.Base64, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Haxe.Crypto.Base64, key}
    Process.put(static_key, {:set, value})
    value
  end
  def chars() do
    __haxe_static_get__(:chars, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
  end
  def chars(value) do
    __haxe_static_put__(:chars, value)
  end
  def bytes() do
    __haxe_static_get__(:bytes, Bytes.of_string(Haxe.Crypto.Base64.chars(), {:utf8}))
  end
  def bytes(value) do
    __haxe_static_put__(:bytes, value)
  end
  def url_chars() do
    __haxe_static_get__(:url_chars, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
  end
  def url_chars(value) do
    __haxe_static_put__(:url_chars, value)
  end
  def url_bytes() do
    __haxe_static_get__(:url_bytes, Bytes.of_string(Haxe.Crypto.Base64.url_chars(), {:utf8}))
  end
  def url_bytes(value) do
    __haxe_static_put__(:url_bytes, value)
  end
  def encode(bytes, complement) do
    use_complement = if (Kernel.is_nil(complement)), do: true, else: complement
    Base.encode64(apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes]), padding: use_complement)
  end
  def decode(str, complement) do
    use_complement = if (Kernel.is_nil(complement)), do: true, else: complement
    encoded = if (use_complement) do
      String.trim_trailing(str, "=")
    else
      str
    end
    decoded = Base.decode64!(encoded, padding: false)
    Bytes.of_data(decoded)
  end
  def url_encode(bytes, complement) do
    use_complement = if (Kernel.is_nil(complement)), do: false, else: complement
    Base.url_encode64(apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_data, [bytes]), padding: use_complement)
  end
  def url_decode(str, complement) do
    use_complement = if (Kernel.is_nil(complement)), do: false, else: complement
    encoded = if (use_complement) do
      String.trim_trailing(str, "=")
    else
      str
    end
    decoded = Base.url_decode64!(encoded, padding: false)
    Bytes.of_data(decoded)
  end
end
