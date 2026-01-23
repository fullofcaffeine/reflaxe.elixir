defmodule FPHelper do
  def i32_to_float(i) do
    <<value::float-little-size(32)>> = <<i::little-signed-size(32)>>
value
  end
  def float_to_i32(f) do
    <<value::little-signed-size(32)>> = <<f::float-little-size(32)>>
value
  end
  def i64_to_double(low, high) do
    <<value::float-little-size(64)>> = <<low::little-signed-size(32), high::little-signed-size(32)>>
value
  end
  def double_to_i64(v) do
    <<value::little-signed-size(64)>> = <<v::float-little-size(64)>>
value
  end
end
