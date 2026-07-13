defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    assert_that(Haxe.Crypto.Crc32.make(Bytes.of_string("", {:utf8})) == 0, "crc32 empty failed")
    assert_that(Haxe.Crypto.Crc32.make(Bytes.of_string("abc", {:utf8})) == 891568578, "crc32 abc failed")
    crc = Haxe.Crypto.Crc32.new()
    prefix = Bytes.of_string("ab", {:utf8})
    crc = apply(Map.get(crc, :__reflaxe_class__) || Map.get(crc, :__struct__), :update, [crc, prefix, 0, prefix.length])
    crc = apply(Map.get(crc, :__reflaxe_class__) || Map.get(crc, :__struct__), :byte, [crc, 99])
    assert_that(apply(Map.get(crc, :__reflaxe_class__) || Map.get(crc, :__struct__), :get, [crc]) == 891568578, "crc32 incremental failed")
    high_crc = Bytes.alloc(1)
    apply(Map.get(high_crc, :__reflaxe_class__) || Map.get(high_crc, :__struct__), :set, [high_crc, 0, 0])
    assert_that(Haxe.Crypto.Crc32.make(high_crc) == -771559539, "crc32 signed int failed")
    assert_that(Haxe.Crypto.Adler32.make(Bytes.of_string("", {:utf8})) == 1, "adler32 empty failed")
    assert_that(Haxe.Crypto.Adler32.make(Bytes.of_string("abc", {:utf8})) == 38600999, "adler32 abc failed")
    adler = Haxe.Crypto.Adler32.new()
    adler = apply(Map.get(adler, :__reflaxe_class__) || Map.get(adler, :__struct__), :update, [adler, prefix, 0, prefix.length])
    suffix = Bytes.of_string("c", {:utf8})
    adler = apply(Map.get(adler, :__reflaxe_class__) || Map.get(adler, :__struct__), :update, [adler, suffix, 0, suffix.length])
    assert_that(apply(Map.get(adler, :__reflaxe_class__) || Map.get(adler, :__struct__), :get, [adler]) == 38600999, "adler32 incremental failed")
    assert_that(apply(Map.get(adler, :__reflaxe_class__) || Map.get(adler, :__struct__), :to_string, [adler]) == "0000024D00000127", "adler32 toString failed")
    read = Haxe.Crypto.Adler32.read(BytesInput.new(Bytes.of_hex("024d0127"), nil, nil))
    assert_that(apply(Map.get(read, :__reflaxe_class__) || Map.get(read, :__struct__), :equals, [read, adler]), "adler32 read/equals failed")
    high_adler = Bytes.alloc(16)
    _g = 0
    high_adler_length = high_adler.length
    high_adler = Enum.reduce(0..(high_adler_length - 1)//1, high_adler, fn i, high_adler_acc ->
      apply(Map.get(high_adler_acc, :__reflaxe_class__) || Map.get(high_adler_acc, :__struct__), :set, [high_adler_acc, i, 255])
      high_adler_acc
    end)
    assert_that(Haxe.Crypto.Adler32.make(high_adler) == -2021126159, "adler32 signed int failed")
  end
end
