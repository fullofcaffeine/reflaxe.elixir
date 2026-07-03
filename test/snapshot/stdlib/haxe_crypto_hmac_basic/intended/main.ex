defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    empty = Bytes.of_string("", nil)
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Hmac.new({:md5})
  reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :make, [reflaxe_dispatch_receiver, empty, empty])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "74e6f7298a9c2d168935f58c001bad88", "hmac md5 empty failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Hmac.new({:sha1})
  reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :make, [reflaxe_dispatch_receiver, empty, empty])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d", "hmac sha1 empty failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Hmac.new({:sha256})
  reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :make, [reflaxe_dispatch_receiver, empty, empty])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad", "hmac sha256 empty failed")
    key = Bytes.of_string("key", nil)
    msg = Bytes.of_string("The quick brown fox jumps over the lazy dog", nil)
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Hmac.new({:md5})
  reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :make, [reflaxe_dispatch_receiver, key, msg])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "80070713463e7749b90c2dc24911e275", "hmac md5 quick fox failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Hmac.new({:sha1})
  reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :make, [reflaxe_dispatch_receiver, key, msg])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9", "hmac sha1 quick fox failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Hmac.new({:sha256})
  reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :make, [reflaxe_dispatch_receiver, key, msg])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8", "hmac sha256 quick fox failed")
  end
end
