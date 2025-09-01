defmodule FPHelper do
  import Bitwise
  defp _i32_to_float(i) do
    sign = 1 - (i >>> 31 <<< 1)
    e = i >>> 23 &&& 255
    if (e == 255) do
      if ((i &&& 8388607) == 0) do
        if (sign > 0), do: Math.POSITIVE_INFINITY, else: Math.NEGATIVE_INFINITY
      else
        Math.NaN
      end
    end
    m = if (e == 0) do
  (i &&& 8388607) <<< 1
else
  i &&& 8388607 ||| 8388608
end
    sign * m * Math.pow(2, e - 150)
  end
  defp _i64_to_double(lo, hi) do
    sign = 1 - (hi >>> 31 <<< 1)
    e = hi >>> 20 &&& 2047
    if (e == 2047) do
      if (lo == 0 && (hi &&& 1048575) == 0) do
        if (sign > 0), do: Math.POSITIVE_INFINITY, else: Math.NEGATIVE_INFINITY
      else
        Math.NaN
      end
    end
    m = 2.22044604925031308e-16 * ((hi &&& 1048575) * 4294967296 + (lo >>> 31) * 2147483648 + (lo &&& 2147483647))
    m = if (e == 0), do: m * 2, else: m + 1
    sign * m * Math.pow(2, e - 1023)
  end
  defp _float_to_i32(f) do
    if (f == 0), do: 0
    af = if (f < 0) do
  -f
else
  f
end
    exp = Math.floor(Math.log(af) / 0.693147180559945286)
    if (exp > 127) do
      2139095040
    else
      if (exp <= -127) do
        exp = -127
        af = af * 7.1362384635298e+44
      else
        af = (af / Math.pow(2, exp) - 1) * 8388608
      end
      (if (f < 0), do: -2147483648, else: 0) ||| exp + 127 <<< 23 ||| Math.round(af)
    end
  end
  defp _double_to_i64(v) do
    i_6_4 = FPHelper.i64tmp
    if (v == 0) do
      low = 0
      high = 0
    else
      if (not Math.is_finite(v)) do
        low = 0
        high = if (v > 0), do: 2146435072, else: -1048576
      else
        av = if (v < 0) do
  -v
else
  v
end
        exp = Math.floor(Math.log(av) / 0.693147180559945286)
        if (exp > 1023) do
          low = -1
          high = 2146435071
        else
          if (exp <= -1023) do
            exp = -1023
            av = av / 2.22507385850720138e-308
          else
            av = av / Math.pow(2, exp) - 1
          end
          sig = Math.round(av * 4503599627370496)
          sig_l = Std.int(sig)
          sig_h = Std.int(sig / 4294967296)
          low = sig_l
          high = (if (v < 0), do: -2147483648, else: 0) ||| exp + 1023 <<< 20 ||| sig_h
        end
      end
    end
    i_6_4
  end
  def i32_to_float(i) do
    sign = 1 - (i >>> 31 <<< 1)
    e = i >>> 23 &&& 255
    if (e == 255) do
      if ((i &&& 8388607) == 0) do
        if (sign > 0), do: Math.POSITIVE_INFINITY, else: Math.NEGATIVE_INFINITY
      else
        Math.NaN
      end
    else
      m = if (e == 0) do
  (i &&& 8388607) <<< 1
else
  i &&& 8388607 ||| 8388608
end
      sign * m * Math.pow(2, e - 150)
    end
  end
  def float_to_i32(f) do
    if (f == 0) do
      0
    else
      af = if (f < 0) do
  -f
else
  f
end
      exp = Math.floor(Math.log(af) / 0.693147180559945286)
      if (exp > 127) do
        2139095040
      else
        if (exp <= -127) do
          exp = -127
          af = af * 7.1362384635298e+44
        else
          af = (af / Math.pow(2, exp) - 1) * 8388608
        end
        (if (f < 0), do: -2147483648, else: 0) ||| exp + 127 <<< 23 ||| Math.round(af)
      end
    end
  end
  def i64_to_double(low, high) do
    sign = 1 - (high >>> 31 <<< 1)
    e = high >>> 20 &&& 2047
    if (e == 2047) do
      if (low == 0 && (high &&& 1048575) == 0) do
        if (sign > 0), do: Math.POSITIVE_INFINITY, else: Math.NEGATIVE_INFINITY
      else
        Math.NaN
      end
    else
      m = 2.22044604925031308e-16 * ((high &&& 1048575) * 4294967296 + (low >>> 31) * 2147483648 + (low &&& 2147483647))
      m = if (e == 0), do: m * 2, else: m + 1
      sign * m * Math.pow(2, e - 1023)
    end
  end
  def double_to_i64(v) do
    i_6_4 = FPHelper.i64tmp
    if (v == 0) do
      low = 0
      high = 0
    else
      if (not Math.is_finite(v)) do
        low = 0
        high = if (v > 0), do: 2146435072, else: -1048576
      else
        av = if (v < 0) do
  -v
else
  v
end
        exp = Math.floor(Math.log(av) / 0.693147180559945286)
        if (exp > 1023) do
          low = -1
          high = 2146435071
        else
          if (exp <= -1023) do
            exp = -1023
            av = av / 2.22507385850720138e-308
          else
            av = av / Math.pow(2, exp) - 1
          end
          sig = Math.round(av * 4503599627370496)
          sig_l = Std.int(sig)
          sig_h = Std.int(sig / 4294967296)
          low = sig_l
          high = (if (v < 0), do: -2147483648, else: 0) ||| exp + 1023 <<< 20 ||| sig_h
        end
      end
    end
    i_6_4
  end
end