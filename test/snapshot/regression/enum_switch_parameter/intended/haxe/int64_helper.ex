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
    s = StringTools.trim(s_param)
    if (s.charAt(0) == "-") do
      s_is_negative = true
      s = s.substring(1, s.length)
    end
    len = s.length
    g = 0
    g1 = len
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < g1) do
    i = g = g + 1
    digit_int = (s.charCodeAt(((len - 1) - i)) - 48)
    if (digit_int < 0 || digit_int > 9) do
      throw("NumberFormatError")
    end
    if (digit_int != 0) do
      digit_low = nil
      digit_high = nil
      digit_high = digit_int >>> 31
      digit_low = digit_int
      if s_is_negative do
        b_low = nil
        b_high = nil
        mask = 65535
        al = multiplier.low &&& mask
        ah = multiplier.low >>> 16
        bl = digit_low &&& mask
        bh = digit_low >>> 16
        p00 = al * bl
        p10 = ah * bl
        p01 = al * bh
        p11 = ah * bh
        low = p00
        high = p11 + p01 >>> 16 + p10 >>> 16
        p01 = p01 <<< 16
        low = low + p01
        ret = high = high + 1
        high = high
        p10 = p10 <<< 16
        low = low + p10
        ret = high = high + 1
        high = high
        high = high + multiplier.low * digit_high + multiplier.high * digit_low
        b_high = high
        b_low = low
        high = (current.high - b_high)
        low = (current.low - b_low)
        ret = high = (high - 1)
        high = high
        x = ___Int64.new(high, low)
        this1 = nil
        this1 = x
        current = if Int32_Impl_.ucompare(low, p01) < 0, do: ret
if Int32_Impl_.ucompare(low, p10) < 0, do: ret
if Int32_Impl_.ucompare(current.low, b_low) < 0, do: ret
this1
        if (not (current.high < 0)) do
          throw("NumberFormatError: Underflow")
        end
      else
        b_low = nil
        b_high = nil
        mask = 65535
        al = multiplier.low &&& mask
        ah = multiplier.low >>> 16
        bl = digit_low &&& mask
        bh = digit_low >>> 16
        p00 = al * bl
        p10 = ah * bl
        p01 = al * bh
        p11 = ah * bh
        low = p00
        high = p11 + p01 >>> 16 + p10 >>> 16
        p01 = p01 <<< 16
        low = low + p01
        ret = high = high + 1
        high = high
        p10 = p10 <<< 16
        low = low + p10
        ret = high = high + 1
        high = high
        high = high + multiplier.low * digit_high + multiplier.high * digit_low
        b_high = high
        b_low = low
        high = current.high + b_high
        low = current.low + b_low
        ret = high = high + 1
        high = high
        x = ___Int64.new(high, low)
        this1 = nil
        this1 = x
        current = if Int32_Impl_.ucompare(low, p01) < 0, do: ret
if Int32_Impl_.ucompare(low, p10) < 0, do: ret
if Int32_Impl_.ucompare(low, current.low) < 0, do: ret
this1
        if (current.high < 0) do
          throw("NumberFormatError: Overflow")
        end
      end
    end
    mask = 65535
    al = multiplier.low &&& mask
    ah = multiplier.low >>> 16
    bl = base_low &&& mask
    bh = base_low >>> 16
    p00 = al * bl
    p10 = ah * bl
    p01 = al * bh
    p11 = ah * bh
    low = p00
    high = p11 + p01 >>> 16 + p10 >>> 16
    p01 = p01 <<< 16
    low = low + p01
    ret = high = high + 1
    high = high
    p10 = p10 <<< 16
    low = low + p10
    ret = high = high + 1
    high = high
    high = high + multiplier.low * base_high + multiplier.high * base_low
    x = ___Int64.new(high, low)
    this1 = nil
    this1 = x
    multiplier = if Int32_Impl_.ucompare(low, p01) < 0, do: ret
if Int32_Impl_.ucompare(low, p10) < 0, do: ret
this1
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    current
  end
  def from_float(f) do
    if (Math.is_na_n(f) || not Math.is_finite(f)) do
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (rest >= 1) do
    curr = rest rem 2
    rest = rest / 2
    if (curr >= 1) do
      a_low = nil
      a_high = nil
      a_high = 0
      a_low = 1
      b = i
      b = b &&& 63
      high = a_high
      low = a_low
      x = ___Int64.new(high, low)
      this1 = nil
      this1 = x
      high = a_high <<< b ||| a_low >>> (32 - b)
      low = a_low <<< b
      x = ___Int64.new(high, low)
      this1 = nil
      this1 = x
      high = a_low <<< (b - 32)
      x = ___Int64.new(high, 0)
      this1 = nil
      this1 = x
      b = if b == 0 do
  this1
else
  if b < 32, do: this1, else: this1
end
      high = result.high + b.high
      low = result.low + b.low
      ret = high = high + 1
      high = high
      x = ___Int64.new(high, low)
      this1 = nil
      this1 = x
      result = b
if Int32_Impl_.ucompare(low, result.low) < 0, do: ret
this1
    end
    i = i + 1
    {:cont, acc}
  else
    {:halt, acc}
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