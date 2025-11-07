defmodule BitwiseOperations do
  @import :Bitwise

  def test_bitwise() do
    a = 255
    b = 15
    and_result = Bitwise.band(a, b)
    or_result = Bitwise.bor(a, b)
    xor_result = Bitwise.bxor(a, b)
    not_result = ~~~a
    left_shift = Bitwise.bsl(a, 2)
    right_shift = Bitwise.bsr(a, 2)
    and_result + or_result + xor_result + not_result + left_shift + right_shift
  end
  def complex_bitwise() do
    mask = 255
    value = 305419896
    Bitwise.bor(Bitwise.band(value, mask), Bitwise.band(Bitwise.bsr(value, 8), mask))
  end
end
