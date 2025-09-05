defmodule Int64Helper do
  import Bitwise
  def parse_string(s_param) do
    base_low = nil
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
    if (s.charAt(0) == "-") do
      s_is_negative = true
      s = s.substring(1, s.length)
    end
    len = s.length
    g = 0
    g1 = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {p01, this1, this1, digit_high, current, b_low, g, p10, g1, low, p01, p10, b_low, multiplier, high, low, low, high, p01, digit_low, high, high, b_high, p10, b_high, high, this1, :ok}, fn _, {acc_p01, acc_this1, acc_this1, acc_digit_high, acc_current, acc_b_low, acc_g, acc_p10, acc_g1, acc_low, acc_p01, acc_p10, acc_b_low, acc_multiplier, acc_high, acc_low, acc_low, acc_high, acc_p01, acc_digit_low, acc_high, acc_high, acc_b_high, acc_p10, acc_b_high, acc_high, acc_this1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    digit_int = (s.charCodeAt(((len - 1) - i)) - 48)
    if (digit_int < 0 || digit_int > 9) do
      throw("NumberFormatError")
    end
    if (digit_int != 0) do
      acc_digit_low = nil
      acc_digit_high = nil
      acc_digit_high = digit_int >>> 31
      acc_digit_low = digit_int
      if s_is_negative do
        acc_b_low = nil
        acc_b_high = nil
        mask = 65535
        al = acc_multiplier.low &&& mask
        ah = acc_multiplier.low >>> 16
        bl = acc_digit_low &&& mask
        bh = acc_digit_low >>> 16
        p00 = al * bl
        acc_p10 = ah * bl
        acc_p01 = al * bh
        p11 = ah * bh
        acc_low = p00
        acc_high = p11 + acc_p01 >>> 16 + acc_p10 >>> 16
        acc_p01 = acc_p01 <<< 16
        acc_low = acc_low + acc_p01
        ret = acc_high = acc_high + 1
        acc_high = acc_high
        acc_p10 = acc_p10 <<< 16
        acc_low = acc_low + acc_p10
        ret = acc_high = acc_high + 1
        acc_high = acc_high
        acc_high = acc_high + acc_multiplier.low * acc_digit_high + acc_multiplier.high * acc_digit_low
        acc_b_high = acc_high
        acc_b_low = acc_low
        acc_high = (acc_current.high - acc_b_high)
        acc_low = (acc_current.low - acc_b_low)
        ret = acc_high = (acc_high - 1)
        acc_high = acc_high
        x = ___Int64.new(acc_high, acc_low)
        acc_this1 = nil
        acc_this1 = x
        acc_current = if Int32_Impl_.ucompare(acc_low, acc_p01) < 0, do: ret
if Int32_Impl_.ucompare(acc_low, acc_p10) < 0, do: ret
if Int32_Impl_.ucompare(acc_current.low, acc_b_low) < 0, do: ret
acc_this1
        if (not (acc_current.high < 0)) do
          throw("NumberFormatError: Underflow")
        end
      else
        acc_b_low = nil
        acc_b_high = nil
        mask = 65535
        al = acc_multiplier.low &&& mask
        ah = acc_multiplier.low >>> 16
        bl = acc_digit_low &&& mask
        bh = acc_digit_low >>> 16
        p00 = al * bl
        acc_p10 = ah * bl
        acc_p01 = al * bh
        p11 = ah * bh
        acc_low = p00
        acc_high = p11 + acc_p01 >>> 16 + acc_p10 >>> 16
        acc_p01 = acc_p01 <<< 16
        acc_low = acc_low + acc_p01
        ret = acc_high = acc_high + 1
        acc_high = acc_high
        acc_p10 = acc_p10 <<< 16
        acc_low = acc_low + acc_p10
        ret = acc_high = acc_high + 1
        acc_high = acc_high
        acc_high = acc_high + acc_multiplier.low * acc_digit_high + acc_multiplier.high * acc_digit_low
        acc_b_high = acc_high
        acc_b_low = acc_low
        acc_high = acc_current.high + acc_b_high
        acc_low = acc_current.low + acc_b_low
        ret = acc_high = acc_high + 1
        acc_high = acc_high
        x = ___Int64.new(acc_high, acc_low)
        acc_this1 = nil
        acc_this1 = x
        acc_current = if Int32_Impl_.ucompare(acc_low, acc_p01) < 0, do: ret
if Int32_Impl_.ucompare(acc_low, acc_p10) < 0, do: ret
if Int32_Impl_.ucompare(acc_low, acc_current.low) < 0, do: ret
acc_this1
        if (acc_current.high < 0) do
          throw("NumberFormatError: Overflow")
        end
      end
    end
    mask = 65535
    al = acc_multiplier.low &&& mask
    ah = acc_multiplier.low >>> 16
    bl = base_low &&& mask
    bh = base_low >>> 16
    p00 = al * bl
    acc_p10 = ah * bl
    acc_p01 = al * bh
    p11 = ah * bh
    acc_low = p00
    acc_high = p11 + acc_p01 >>> 16 + acc_p10 >>> 16
    acc_p01 = acc_p01 <<< 16
    acc_low = acc_low + acc_p01
    ret = acc_high = acc_high + 1
    acc_high = acc_high
    acc_p10 = acc_p10 <<< 16
    acc_low = acc_low + acc_p10
    ret = acc_high = acc_high + 1
    acc_high = acc_high
    acc_high = acc_high + acc_multiplier.low * base_high + acc_multiplier.high * base_low
    x = ___Int64.new(acc_high, acc_low)
    acc_this1 = nil
    acc_this1 = x
    acc_multiplier = if Int32_Impl_.ucompare(acc_low, acc_p01) < 0, do: ret
if Int32_Impl_.ucompare(acc_low, acc_p10) < 0, do: ret
acc_this1
    {:cont, {acc_p01, acc_this1, acc_this1, acc_digit_high, acc_current, acc_b_low, acc_g, acc_p10, acc_g1, acc_low, acc_p01, acc_p10, acc_b_low, acc_multiplier, acc_high, acc_low, acc_low, acc_high, acc_p01, acc_digit_low, acc_high, acc_high, acc_b_high, acc_p10, acc_b_high, acc_high, acc_this1, acc_state}}
  else
    {:halt, {acc_p01, acc_this1, acc_this1, acc_digit_high, acc_current, acc_b_low, acc_g, acc_p10, acc_g1, acc_low, acc_p01, acc_p10, acc_b_low, acc_multiplier, acc_high, acc_low, acc_low, acc_high, acc_p01, acc_digit_low, acc_high, acc_high, acc_b_high, acc_p10, acc_b_high, acc_high, acc_this1, acc_state}}
  end
end)
    current
  end
  def from_float(f) do
    if (f != f || not (f == f && f != 1 / 0 && f != 1 / 0 * -1)) do
      throw("Number is NaN or Infinite")
    end
    no_fractions = (f - f rem 1)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {a_high, high, rest, this1, this1, i, this1, a_low, result, this1, b, :ok}, fn _, {acc_a_high, acc_high, acc_rest, acc_this1, acc_this1, acc_i, acc_this1, acc_a_low, acc_result, acc_this1, acc_b, acc_state} ->
  if (acc_rest >= 1) do
    curr = acc_rest rem 2
    acc_rest = acc_rest / 2
    if (curr >= 1) do
      acc_a_low = nil
      acc_a_high = nil
      acc_a_high = 0
      acc_a_low = 1
      acc_b = acc_i
      acc_b = acc_b &&& 63
      acc_high = acc_a_high
      low = acc_a_low
      x = ___Int64.new(acc_high, low)
      acc_this1 = nil
      acc_this1 = x
      acc_high = acc_a_high <<< acc_b ||| acc_a_low >>> (32 - acc_b)
      low = acc_a_low <<< acc_b
      x = ___Int64.new(acc_high, low)
      acc_this1 = nil
      acc_this1 = x
      acc_high = acc_a_low <<< (acc_b - 32)
      x = ___Int64.new(acc_high, 0)
      acc_this1 = nil
      acc_this1 = x
      acc_b = if acc_b == 0 do
  acc_this1
else
  if acc_b < 32, do: acc_this1, else: acc_this1
end
      acc_high = acc_result.high + acc_b.high
      low = acc_result.low + acc_b.low
      ret = acc_high = acc_high + 1
      acc_high = acc_high
      x = ___Int64.new(acc_high, low)
      acc_this1 = nil
      acc_this1 = x
      acc_result = acc_b
if Int32_Impl_.ucompare(low, acc_result.low) < 0, do: ret
acc_this1
    end
    acc_i = acc_i + 1
    {:cont, {acc_a_high, acc_high, acc_rest, acc_this1, acc_this1, acc_i, acc_this1, acc_a_low, acc_result, acc_this1, acc_b, acc_state}}
  else
    {:halt, {acc_a_high, acc_high, acc_rest, acc_this1, acc_this1, acc_i, acc_this1, acc_a_low, acc_result, acc_this1, acc_b, acc_state}}
  end
end)
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