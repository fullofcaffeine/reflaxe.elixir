defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    hello = Bytes.of_string("hello", nil)
    _ = assert_that(Haxe.Crypto.Base64.encode(hello, nil) == "aGVsbG8=", "standard padded encode failed")
    _ = assert_that(Haxe.Crypto.Base64.encode(hello, false) == "aGVsbG8", "standard unpadded encode failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Base64.decode("aGVsbG8=", nil)
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
end).() == "hello", "standard padded decode failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Base64.decode("aGVsbG8", false)
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
end).() == "hello", "standard unpadded decode failed")
    url = Bytes.of_string("fo?", nil)
    _ = assert_that(Haxe.Crypto.Base64.url_encode(url, nil) == "Zm8_", "url unpadded encode failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Base64.url_decode("Zm8_", nil)
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
end).() == "fo?", "url unpadded decode failed")
    short_url = Bytes.of_string("fo", nil)
    _ = assert_that(Haxe.Crypto.Base64.url_encode(short_url, true) == "Zm8=", "url padded encode failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Base64.url_decode("Zm8=", true)
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
end).() == "fo", "url padded decode failed")
    binary = Bytes.alloc(3)
    _ = apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 0, 251])
    _ = apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 1, 255])
    _ = apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 2, 0])
    _ = assert_that(Haxe.Crypto.Base64.encode(binary, nil) == "+/8A", "standard alphabet encode failed")
    _ = assert_that(Haxe.Crypto.Base64.url_encode(binary, nil) == "-_8A", "url alphabet encode failed")
  end
end
