defmodule FPHelper do
  @moduledoc """
    FPHelper module generated from Haxe

      Helper that converts between floating point and binary representation.
      Always works in low-endian encoding.
  """

  # Static functions
  @doc "Generated from Haxe _i32ToFloat"
  def i32_to_float(i) do
    temp_result = nil
    temp_number = nil

    sign = (1 - (Bitwise.bsl(Bitwise.bsr(i, 31), 1)))

    e = (Bitwise.bsr(i, 23) and 255)

    if ((e == 255)) do
      if ((((i and 8388607)) == 0)) do
        if ((sign > 0)), do: temp_result = Math.p_o_s_i_t_i_v_e__i_n_f_i_n_i_t_y, else: temp_result = Math.n_e_g_a_t_i_v_e__i_n_f_i_n_i_t_y
      else
        temp_result = Math.na_n
      end
      temp_result
    else
      nil
    end

    if ((e == 0)), do: temp_number = Bitwise.bsl(((i and 8388607)), 1), else: temp_number = ((i and 8388607) or 8388608)

    m = temp_number

    ((sign * m) * Math.pow(2, (e - 150)))
  end

  @doc "Generated from Haxe _i64ToDouble"
  def i64_to_double(lo, hi) do
    temp_result = nil
    temp_right = nil

    sign = (1 - (Bitwise.bsl(Bitwise.bsr(hi, 31), 1)))

    e = (Bitwise.bsr(hi, 20) and 2047)

    if ((e == 2047)) do
      if (((lo == 0) && (((hi and 1048575)) == 0))) do
        if ((sign > 0)), do: temp_result = Math.p_o_s_i_t_i_v_e__i_n_f_i_n_i_t_y, else: temp_result = Math.n_e_g_a_t_i_v_e__i_n_f_i_n_i_t_y
      else
        temp_result = Math.na_n
      end
      temp_result
    else
      nil
    end

    m = (2.220446049250313e-16 * ((((((hi and 1048575)) * 4294967296.) + ((Bitwise.bsr(lo, 31)) * 2147483648.)) + ((lo and 2147483647)))))

    if ((e == 0)), do: temp_right = (m * 2.0), else: temp_right = (m + 1.0)

    m = temp_right

    ((sign * m) * Math.pow(2, (e - 1023)))
  end

  @doc "Generated from Haxe _floatToI32"
  def float_to_i32(f) do
    temp_number = nil
    temp_number1 = nil

    if ((f == 0)) do
      0
    else
      nil
    end

    if ((f < 0)), do: temp_number = -f, else: temp_number = f

    af = temp_number

    exp = Math.floor((Math.log(af) / 0.6931471805599453))

    if ((exp > 127)) do
      2139095040
    else
      if ((exp <= -127)) do
        exp = -127
        af = af * 7.1362384635298e+44
      else
        af = ((((af / Math.pow(2, exp)) - 1.0)) * 8388608)
      end
      if ((f < 0)), do: temp_number1 = -2147483648, else: temp_number1 = 0
      ((temp_number1 or Bitwise.bsl((exp + 127), 23)) or Math.round(af))
    end
  end

  @doc "Generated from Haxe _doubleToI64"
  def double_to_i64(v) do
    temp_right = nil
    temp_number = nil
    temp_number1 = nil

    i64 = FPHelper.i64tmp

    if ((v == 0)) do
      %{i64 | low: 0}
      %{i64 | high: 0}
    else
      if (not Math.is_finite(v)) do
        %{i64 | low: 0}
        if ((v > 0)), do: temp_right = 2146435072, else: temp_right = -1048576
        %{i64 | high: temp_right}
      else
        if ((v < 0)), do: temp_number = -v, else: temp_number = v
        av = temp_number
        exp = Math.floor((Math.log(av) / 0.6931471805599453))
        if ((exp > 1023)) do
          %{i64 | low: -1}
          %{i64 | high: 2146435071}
        else
          if ((exp <= -1023)) do
            exp = -1023
            av = (av / 2.2250738585072014e-308)
          else
            av = ((av / Math.pow(2, exp)) - 1.0)
          end
          sig = Math.round((av * 4503599627370496.))
          sig_l = Std.int(sig)
          sig_h = Std.int((sig / 4294967296.0))
          %{i64 | low: sig_l}
          if ((v < 0)), do: temp_number1 = -2147483648, else: temp_number1 = 0
          %{i64 | high: ((temp_number1 or Bitwise.bsl((exp + 1023), 20)) or sig_h)}
        end
      end
    end

    i64
  end

  @doc "Generated from Haxe i32ToFloat"
  def i32_to_float(i) do
    temp_result = nil
    temp_number = nil

    sign = (1 - (Bitwise.bsl(Bitwise.bsr(i, 31), 1)))

    e = (Bitwise.bsr(i, 23) and 255)

    if ((e == 255)) do
      if ((((i and 8388607)) == 0)) do
        if ((sign > 0)), do: temp_result = Math.p_o_s_i_t_i_v_e__i_n_f_i_n_i_t_y, else: temp_result = Math.n_e_g_a_t_i_v_e__i_n_f_i_n_i_t_y
      else
        temp_result = Math.na_n
      end
    else
      if ((e == 0)), do: temp_number = Bitwise.bsl(((i and 8388607)), 1), else: temp_number = ((i and 8388607) or 8388608)
      m = temp_number
      temp_result = ((sign * m) * Math.pow(2, (e - 150)))
    end

    temp_result
  end

  @doc "Generated from Haxe floatToI32"
  def float_to_i32(f) do
    temp_result = nil
    temp_number = nil
    temp_number1 = nil

    if ((f == 0)) do
      temp_result = 0
    else
      if ((f < 0)), do: temp_number = -f, else: temp_number = f
      af = temp_number
      exp = Math.floor((Math.log(af) / 0.6931471805599453))
      if ((exp > 127)) do
        temp_result = 2139095040
      else
        if ((exp <= -127)) do
          exp = -127
          af = af * 7.1362384635298e+44
        else
          af = ((((af / Math.pow(2, exp)) - 1.0)) * 8388608)
        end
        if ((f < 0)), do: temp_number1 = -2147483648, else: temp_number1 = 0
        temp_result = ((temp_number1 or Bitwise.bsl((exp + 127), 23)) or Math.round(af))
      end
    end

    temp_result
  end

  @doc "Generated from Haxe i64ToDouble"
  def i64_to_double(low, high) do
    temp_result = nil
    temp_right = nil

    sign = (1 - (Bitwise.bsl(Bitwise.bsr(high, 31), 1)))

    e = (Bitwise.bsr(high, 20) and 2047)

    if ((e == 2047)) do
      if (((low == 0) && (((high and 1048575)) == 0))) do
        if ((sign > 0)), do: temp_result = Math.p_o_s_i_t_i_v_e__i_n_f_i_n_i_t_y, else: temp_result = Math.n_e_g_a_t_i_v_e__i_n_f_i_n_i_t_y
      else
        temp_result = Math.na_n
      end
    else
      m = (2.220446049250313e-16 * ((((((high and 1048575)) * 4294967296.) + ((Bitwise.bsr(low, 31)) * 2147483648.)) + ((low and 2147483647)))))
      if ((e == 0)), do: temp_right = (m * 2.0), else: temp_right = (m + 1.0)
      m = temp_right
      temp_result = ((sign * m) * Math.pow(2, (e - 1023)))
    end

    temp_result
  end

  @doc "Generated from Haxe doubleToI64"
  def double_to_i64(v) do
    temp_right = nil
    temp_number = nil
    temp_number1 = nil

    i64 = FPHelper.i64tmp

    if ((v == 0)) do
      %{i64 | low: 0}
      %{i64 | high: 0}
    else
      if (not Math.is_finite(v)) do
        %{i64 | low: 0}
        if ((v > 0)), do: temp_right = 2146435072, else: temp_right = -1048576
        %{i64 | high: temp_right}
      else
        if ((v < 0)), do: temp_number = -v, else: temp_number = v
        av = temp_number
        exp = Math.floor((Math.log(av) / 0.6931471805599453))
        if ((exp > 1023)) do
          %{i64 | low: -1}
          %{i64 | high: 2146435071}
        else
          if ((exp <= -1023)) do
            exp = -1023
            av = (av / 2.2250738585072014e-308)
          else
            av = ((av / Math.pow(2, exp)) - 1.0)
          end
          sig = Math.round((av * 4503599627370496.))
          sig_l = Std.int(sig)
          sig_h = Std.int((sig / 4294967296.0))
          %{i64 | low: sig_l}
          if ((v < 0)), do: temp_number1 = -2147483648, else: temp_number1 = 0
          %{i64 | high: ((temp_number1 or Bitwise.bsl((exp + 1023), 20)) or sig_h)}
        end
      end
    end

    i64
  end

end
