defmodule Int64Helper do
  import Bitwise
  def parse_string(s_param) do
    base_low = nil
    base_high = nil
    base_high = 0
    base_low = 10
    x = ___Int64.new(0, 0)
    this1 = nil
    this1 = x
    current = this1
    x = ___Int64.new(0, 1)
    this1 = nil
    this1 = x
    multiplier = this1
    s_is_negative = false
    s = StringTools.ltrim(StringTools.rtrim(s_param))
    if (s.char_at(0) == "-") do
      s_is_negative = true
      s = s.substring(1, s.length)
    end
    len = length(s)
    g = 0
    g1 = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {digit_high, this1, digit_low, high, this1, low, low, high, p10, p10, b_high, this1, high, p10, b_low, b_low, multiplier, high, low, g, current, p01, p01, p01, b_high, high, g1, :ok}, fn _, {acc_digit_high, acc_this1, acc_digit_low, acc_high, acc_this1, acc_low, acc_low, acc_high, acc_p10, acc_p10, acc_b_high, acc_this1, acc_high, acc_p10, acc_b_low, acc_b_low, acc_multiplier, acc_high, acc_low, acc_g, acc_current, acc_p01, acc_p01, acc_p01, acc_b_high, acc_high, acc_g1, acc_state} -> nil end)
    current
  end
  def from_float(f) do
    if (f != f || not (f == f && f != 1 / 0 && f != 1 / 0 * -1)) do
      throw("Number is NaN or Infinite")
    end
    no_fractions = (f - rem(f, 1))
    if (no_fractions > 9007199254740991) do
      throw("Conversion overflow")
    end
    if (no_fractions < -9007199254740991) do
      throw("Conversion underflow")
    end
    x = ___Int64.new(0, 0)
    this1 = nil
    this1 = x
    result = this1
    neg = no_fractions < 0
    rest = if neg do
  -no_fractions
else
  no_fractions
end
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {this1, b, a_high, this1, this1, i, a_low, high, result, rest, this1, :ok}, fn _, {acc_this1, acc_b, acc_a_high, acc_this1, acc_this1, acc_i, acc_a_low, acc_high, acc_result, acc_rest, acc_this1, acc_state} -> nil end)
    if neg do
      high = ~~~result.high
      low = ~~~result.low + 1
      ret = high = high + 1
      high = high
      x = ___Int64.new(high, low)
      this1 = nil
      this1 = x
      result = if low == 0, do: ret
this1
    end
    result
  end
end