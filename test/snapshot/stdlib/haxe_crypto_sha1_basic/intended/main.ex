defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    assert_that(Haxe.Crypto.Sha1.encode("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d", "sha1 encode abc failed")
    assert_that(Haxe.Crypto.Sha1.encode("") == "da39a3ee5e6b4b0d3255bfef95601890afd80709", "sha1 encode empty failed")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Haxe.Crypto.Sha1.make(Bytes.of_string("abc", {:utf8}))
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "a9993e364706816aba3e25717850c26c9cd0d89d", "sha1 make abc failed")
    binary = Bytes.alloc(3)
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 0, 0])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 1, 255])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 2, 16])
    assert_that((fn ->
      reflaxe_dispatch_receiver = Haxe.Crypto.Sha1.make(binary)
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "a14c2fba17201c1ead45b6c4af4409fbfc16ba8a", "sha1 make binary failed")
  end
end
