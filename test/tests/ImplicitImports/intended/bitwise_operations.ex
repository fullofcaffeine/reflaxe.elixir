defmodule BitwiseOperations do
  import Bitwise
  def testBitwise() do
    a = 255
    b = 15
    and_result = a &&& b
    or_result = a ||| b
    xor_result = a ^^^ b
    not_result = ~~~a
    left_shift = a <<< 2
    right_shift = a >>> 2
    and_result + or_result + xor_result + not_result + left_shift + right_shift
  end
  def complexBitwise() do
    mask = 255
    value = 305419896
    value &&& mask ||| value >>> 8 &&& mask
  end
end