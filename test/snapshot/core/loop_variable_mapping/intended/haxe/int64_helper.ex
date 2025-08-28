defmodule Int64Helper do
  @moduledoc """
    Int64Helper module generated from Haxe

      Helper for parsing to `Int64` instances.
  """

  # Static functions
  @doc "Generated from Haxe parseString"
  def parse_string(s_param) do
    temp_int64 = nil
    temp_int641 = nil
    temp_right = nil
    temp_number = nil
    temp_number1 = nil
    temp_number2 = nil
    temp_right1 = nil
    temp_number3 = nil
    temp_number4 = nil
    temp_number5 = nil
    temp_right2 = nil
    temp_number6 = nil
    temp_number7 = nil

    base_high = 0

    base_low = 10

    temp_int64 = nil

    x = Int64.new(0, 0)
    temp_int64 = x

    temp_int641 = nil

    x = Int64.new(0, 1)
    temp_int641 = x

    s_is_negative = false

    s = StringTools.trim(s_param)

    if ((s.char_at(0) == "-")) do
      s_is_negative = true
      s = s.substring(1, s.length)
    else
      nil
    end

    len = s.length

    g_counter = 0

    g_array = len

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        digit_int = (s.char_code_at(((len - 1) - _i)) - 48)
        if (((digit_int < 0) || (digit_int > 9))) do
          raise "NumberFormatError"
        else
          nil
        end
        if ((digit_int != 0)) do
          digit_low = nil
          digit_high = nil
          digit_high = Bitwise.bsr(digit_int, 31)
          digit_low = digit_int
          if s_is_negative do
            temp_right = nil
            b_low = nil
            b_high = nil
            mask = 65535
            al = (temp_int641.low and mask)
            ah = Bitwise.bsr(temp_int641.low, 16)
            bl = (digit_low and mask)
            bh = Bitwise.bsr(digit_low, 16)
            p00 = (al * bl)
            p10 = (ah * bl)
            p01 = (al * bh)
            p11 = (ah * bh)
            low = p00
            high = ((p11 + (Bitwise.bsr(p01, 16))) + (Bitwise.bsr(p10, 16)))
            p01 = Bitwise.bsl(p01, 16)
            low = (low + p01)
            if ((Int32_Impl_.ucompare(low, p01) < 0)) do
              ret = high + 1
              high = high
              temp_number = ret
              temp_number
            else
              nil
            end
            p10 = Bitwise.bsl(p10, 16)
            low = (low + p10)
            if ((Int32_Impl_.ucompare(low, p10) < 0)) do
              temp_number1 = nil
              ret = high + 1
              high = high
              temp_number1 = ret
              temp_number1
            else
              nil
            end
            high = (high + (((temp_int641.low * digit_high) + (temp_int641.high * digit_low))))
            b_high = high
            b_low = low
            high = (temp_int64.high - b_high)
            low = (temp_int64.low - b_low)
            if ((Int32_Impl_.ucompare(temp_int64.low, b_low) < 0)) do
              temp_number2 = nil
              ret = high - 1
              high = high
              temp_number2 = ret
              temp_number2
            else
              nil
            end
            x = Int64.new(high, low)
            this = nil
            this = x
            temp_right = this
            temp_int64 = temp_right
            if (not ((temp_int64.high < 0))) do
              raise "NumberFormatError: Underflow"
            else
              nil
            end
          else
            temp_right1 = nil
            b_low = nil
            b_high = nil
            mask = 65535
            al = (temp_int641.low and mask)
            ah = Bitwise.bsr(temp_int641.low, 16)
            bl = (digit_low and mask)
            bh = Bitwise.bsr(digit_low, 16)
            p00 = (al * bl)
            p10 = (ah * bl)
            p01 = (al * bh)
            p11 = (ah * bh)
            low = p00
            high = ((p11 + (Bitwise.bsr(p01, 16))) + (Bitwise.bsr(p10, 16)))
            p01 = Bitwise.bsl(p01, 16)
            low = (low + p01)
            if ((Int32_Impl_.ucompare(low, p01) < 0)) do
              temp_number3 = nil
              ret = high + 1
              high = high
              temp_number3 = ret
              temp_number3
            else
              nil
            end
            p10 = Bitwise.bsl(p10, 16)
            low = (low + p10)
            if ((Int32_Impl_.ucompare(low, p10) < 0)) do
              temp_number4 = nil
              ret = high + 1
              high = high
              temp_number4 = ret
              temp_number4
            else
              nil
            end
            high = (high + (((temp_int641.low * digit_high) + (temp_int641.high * digit_low))))
            b_high = high
            b_low = low
            high = (temp_int64.high + b_high)
            low = (temp_int64.low + b_low)
            if ((Int32_Impl_.ucompare(low, temp_int64.low) < 0)) do
              temp_number5 = nil
              ret = high + 1
              high = high
              temp_number5 = ret
              temp_number5
            else
              nil
            end
            x = Int64.new(high, low)
            this = nil
            this = x
            temp_right1 = this
            temp_int64 = temp_right1
            if ((temp_int64.high < 0)) do
              raise "NumberFormatError: Overflow"
            else
              nil
            end
          end
        else
          nil
        end
        temp_right2 = nil
        mask = 65535
        al = (temp_int641.low and mask)
        ah = Bitwise.bsr(temp_int641.low, 16)
        bl = (base_low and mask)
        bh = Bitwise.bsr(base_low, 16)
        p00 = (al * bl)
        p10 = (ah * bl)
        p01 = (al * bh)
        p11 = (ah * bh)
        low = p00
        high = ((p11 + (Bitwise.bsr(p01, 16))) + (Bitwise.bsr(p10, 16)))
        p01 = Bitwise.bsl(p01, 16)
        low = (low + p01)
        if ((Int32_Impl_.ucompare(low, p01) < 0)) do
          temp_number6 = nil
          ret = high + 1
          high = high
          temp_number6 = ret
          temp_number6
        else
          nil
        end
        p10 = Bitwise.bsl(p10, 16)
        low = (low + p10)
        if ((Int32_Impl_.ucompare(low, p10) < 0)) do
          temp_number7 = nil
          ret = high + 1
          high = high
          temp_number7 = ret
          temp_number7
        else
          nil
        end
        high = (high + (((temp_int641.low * base_high) + (temp_int641.high * base_low))))
        x = Int64.new(high, low)
        this = nil
        this = x
        temp_right2 = this
        temp_int641 = temp_right2
        loop.()
      end
    end).()

    temp_int64
  end

  @doc "Generated from Haxe fromFloat"
  def from_float(f) do
    temp_int64 = nil
    temp_number = nil
    temp_int641 = nil
    temp_number1 = nil
    temp_right = nil
    temp_number2 = nil
    temp_right1 = nil

    if ((Math.is_na_n(f) || not Math.is_finite(f))) do
      raise "Number is NaN or Infinite"
    else
      nil
    end

    no_fractions = (f - rem(f, 1))

    if ((no_fractions > 9007199254740991)) do
      raise "Conversion overflow"
    else
      nil
    end

    if ((no_fractions < -9007199254740991)) do
      raise "Conversion underflow"
    else
      nil
    end

    x = Int64.new(0, 0)
    temp_int64 = x

    neg = (no_fractions < 0)

    if neg, do: temp_number = -no_fractions, else: temp_number = no_fractions

    rest = temp_number

    i = 0

    (fn loop ->
      if ((rest >= 1)) do
            curr = rem(rest, 2)
        rest = (rest / 2)
        if ((curr >= 1)) do
          a_low = nil
          a_high = nil
          a_high = 0
          a_low = 1
          _b = _i
          _b = _b and 63
          if ((_b == 0)) do
            high = a_high
            low = a_low
            x = Int64.new(high, low)
            this = nil
            this = x
            temp_int641 = this
          else
            if ((_b < 32)) do
              high = (Bitwise.bsl(a_high, _b) or Bitwise.bsr(a_low, (32 - _b)))
              low = Bitwise.bsl(a_low, _b)
              x = Int64.new(high, low)
              this = nil
              this = x
              temp_int641 = this
            else
              high = Bitwise.bsl(a_low, (_b - 32))
              x = Int64.new(high, 0)
              this = nil
              this = x
              temp_int641 = this
            end
          end
          _b = temp_int641
          high = (temp_int64.high + _b.high)
          low = (temp_int64.low + _b.low)
          if ((Int32_Impl_.ucompare(low, temp_int64.low) < 0)) do
            ret = high + 1
            high = high
            temp_number1 = ret
            temp_number1
          else
            nil
          end
          x = Int64.new(high, low)
          this = nil
          this = x
          temp_right = this
          temp_int64 = temp_right
        else
          nil
        end
        _i + 1
        loop.()
      end
    end).()

    if neg do
      high = Bitwise.bnot(temp_int64.high)
      low = (Bitwise.bnot(temp_int64.low) + 1)
      if ((low == 0)) do
        ret = high + 1
        high = high
        temp_number2 = ret
        temp_number2
      else
        nil
      end
      x = Int64.new(high, low)
      this = nil
      this = x
      temp_right1 = this
      temp_int64 = temp_right1
    else
      nil
    end

    temp_int64
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
