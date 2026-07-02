defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    _ = assert_that(Haxe.Crypto.Sha256.encode("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "sha256 encode abc failed")
    _ = assert_that(Haxe.Crypto.Sha256.encode("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "sha256 encode empty failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Sha256.make(Bytes.of_string("abc", nil))
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "sha256 make abc failed")
    binary = Bytes.alloc(3)
    _ = apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 0, 0])
    _ = apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 1, 255])
    _ = apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 2, 16])
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = Haxe.Crypto.Sha256.make(binary)
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "2da45f2cd1f9c8e69a67abf7a6b26c282533d0a7686787a9533265418680d4d2", "sha256 make binary failed")
  end
end
