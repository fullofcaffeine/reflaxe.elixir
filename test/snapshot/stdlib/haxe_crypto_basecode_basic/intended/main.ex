defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    hex = Haxe.Crypto.BaseCode.new(Bytes.of_string("0123456789abcdef", nil))
    binary = Bytes.of_hex("00ff10")
    encoded_hex = apply(Map.get(hex, :__reflaxe_class__) || Map.get(hex, :__struct__), :encode_bytes, [hex, binary])
    _ = assert_that(apply(Map.get(encoded_hex, :__reflaxe_class__) || Map.get(encoded_hex, :__struct__), :to_string, [encoded_hex]) == "00ff10", "hex encode failed")
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = apply(Map.get(hex, :__reflaxe_class__) || Map.get(hex, :__struct__), :decode_bytes, [hex, Bytes.of_string("00ff10", nil)])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
end).() == "00ff10", "hex decode failed")
    _ = assert_that(Haxe.Crypto.BaseCode.encode("A", "01") == "01000001", "binary string encode failed")
    _ = assert_that(Haxe.Crypto.BaseCode.decode("01000001", "01") == "A", "binary string decode failed")
    try do
      _ = Haxe.Crypto.BaseCode.new(Bytes.of_string("abc", nil))
      _ = assert_that(false, "non-power-of-two dictionary should throw")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {error, _} ->
            assert_that(Reflaxe.Elixir.HaxeFloat.to_string(error) == "BaseCode : base length must be a power of two.", "invalid base length error mismatch")
        end)
    end
    try do
      _ = apply(Map.get(hex, :__reflaxe_class__) || Map.get(hex, :__struct__), :decode_bytes, [hex, Bytes.of_string("0g", nil)])
      _ = assert_that(false, "invalid encoded character should throw")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {error, _} ->
            assert_that(Reflaxe.Elixir.HaxeFloat.to_string(error) == "BaseCode : invalid encoded char", "invalid encoded character error mismatch")
        end)
    end
  end
end
