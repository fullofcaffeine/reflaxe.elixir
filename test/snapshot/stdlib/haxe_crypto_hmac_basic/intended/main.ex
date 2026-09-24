defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    empty = Bytes.of_string("", {:utf8})
    assert_that((fn ->
      reflaxe_dispatch_receiver_node_0 = Haxe.Crypto.Hmac.new({:md5})
      reflaxe_dispatch_receiver_node_1 = apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :make, [reflaxe_dispatch_receiver_node_0, empty, empty])
      apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :to_hex, [reflaxe_dispatch_receiver_node_1])
    end).() == "74e6f7298a9c2d168935f58c001bad88", "hmac md5 empty failed")
    assert_that((fn ->
      reflaxe_dispatch_receiver_node_2 = Haxe.Crypto.Hmac.new({:sha1})
      reflaxe_dispatch_receiver_node_3 = apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :make, [reflaxe_dispatch_receiver_node_2, empty, empty])
      apply(Map.get(reflaxe_dispatch_receiver_node_3, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_3, :__struct__), :to_hex, [reflaxe_dispatch_receiver_node_3])
    end).() == "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d", "hmac sha1 empty failed")
    assert_that((fn ->
      reflaxe_dispatch_receiver_node_4 = Haxe.Crypto.Hmac.new({:sha256})
      reflaxe_dispatch_receiver_node_5 = apply(Map.get(reflaxe_dispatch_receiver_node_4, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_4, :__struct__), :make, [reflaxe_dispatch_receiver_node_4, empty, empty])
      apply(Map.get(reflaxe_dispatch_receiver_node_5, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_5, :__struct__), :to_hex, [reflaxe_dispatch_receiver_node_5])
    end).() == "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad", "hmac sha256 empty failed")
    key = Bytes.of_string("key", {:utf8})
    msg = Bytes.of_string("The quick brown fox jumps over the lazy dog", {:utf8})
    assert_that((fn ->
      reflaxe_dispatch_receiver_node_6 = Haxe.Crypto.Hmac.new({:md5})
      reflaxe_dispatch_receiver_node_7 = apply(Map.get(reflaxe_dispatch_receiver_node_6, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_6, :__struct__), :make, [reflaxe_dispatch_receiver_node_6, key, msg])
      apply(Map.get(reflaxe_dispatch_receiver_node_7, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_7, :__struct__), :to_hex, [reflaxe_dispatch_receiver_node_7])
    end).() == "80070713463e7749b90c2dc24911e275", "hmac md5 quick fox failed")
    assert_that((fn ->
      reflaxe_dispatch_receiver_node_8 = Haxe.Crypto.Hmac.new({:sha1})
      reflaxe_dispatch_receiver_node_9 = apply(Map.get(reflaxe_dispatch_receiver_node_8, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_8, :__struct__), :make, [reflaxe_dispatch_receiver_node_8, key, msg])
      apply(Map.get(reflaxe_dispatch_receiver_node_9, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_9, :__struct__), :to_hex, [reflaxe_dispatch_receiver_node_9])
    end).() == "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9", "hmac sha1 quick fox failed")
    assert_that((fn ->
      reflaxe_dispatch_receiver_node_10 = Haxe.Crypto.Hmac.new({:sha256})
      reflaxe_dispatch_receiver_node_11 = apply(Map.get(reflaxe_dispatch_receiver_node_10, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_10, :__struct__), :make, [reflaxe_dispatch_receiver_node_10, key, msg])
      apply(Map.get(reflaxe_dispatch_receiver_node_11, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_11, :__struct__), :to_hex, [reflaxe_dispatch_receiver_node_11])
    end).() == "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8", "hmac sha256 quick fox failed")
  end
end
