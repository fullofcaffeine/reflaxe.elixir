defmodule FPHelper do
  def i32_to_float(i) do
    Reflaxe.Elixir.HaxeFloat.decode32(<<i::little-signed-size(32)>>)
  end
  def float_to_i32(f) do
    <<value::little-signed-size(32)>> = Reflaxe.Elixir.HaxeFloat.encode32(f); value
  end
  def i64_to_double(low, high) do
    Reflaxe.Elixir.HaxeFloat.decode64(<<low::little-signed-size(32), high::little-signed-size(32)>>)
  end
  def double_to_i64(v) do
    <<value::little-signed-size(64)>> = Reflaxe.Elixir.HaxeFloat.encode64(v); value
  end
end
