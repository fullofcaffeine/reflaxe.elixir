defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    assert_that(Haxe.Crypto.Sha224.encode("abc") == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "sha224 encode abc failed")
    assert_that(Haxe.Crypto.Sha224.encode("") == "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f", "sha224 encode empty failed")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Haxe.Crypto.Sha224.make(Bytes.of_string("abc", {:utf8}))
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "sha224 make abc failed")
    binary = Bytes.alloc(3)
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 0, 0])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 1, 255])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 2, 16])
    assert_that((fn ->
      reflaxe_dispatch_receiver = Haxe.Crypto.Sha224.make(binary)
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "fb00d9d04bdeeb4c51a031ab62ad806c6b8d293efafb8456deae0320", "sha224 make binary failed")
  end
end
