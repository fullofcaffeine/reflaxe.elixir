defmodule Int64Helper do
  def parse_string(s_param) do
    s = String.trim(s_param)
    case Integer.parse(s) do
      {i, ""} ->
        if i < -9223372036854775808 or i > 9223372036854775807 do
          raise Reflaxe.Elixir.HaxeThrow, [value: "NumberFormatError"]
        else
          i
        end
      _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "NumberFormatError"]
    end
  end
  def from_float(f) do
    if (Reflaxe.Elixir.HaxeFloat.is_na_n(f) or not Reflaxe.Elixir.HaxeFloat.is_finite(f)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Number is NaN or Infinite"]
    end
    no_fractions = Reflaxe.Elixir.HaxeFloat.sub(f, Reflaxe.Elixir.HaxeFloat.remainder(f, 1))
    if (Reflaxe.Elixir.HaxeFloat.gt(no_fractions, 9007199254740991)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conversion overflow"]
    end
    if (Reflaxe.Elixir.HaxeFloat.lt(no_fractions, -9007199254740991)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conversion underflow"]
    end
    int32_value = 0
    shift = 31
    x = :erlang.bsr(int32_value, shift)
    high = (reflaxe_i32_clamp = :erlang.band(x, 4294967295)
if reflaxe_i32_clamp >= 2147483648, do: reflaxe_i32_clamp - 4294967296, else: reflaxe_i32_clamp)
    low_unsigned = if int32_value < 0, do: int32_value + 4294967296, else: int32_value
    value = :erlang.bsl(high, 32) + low_unsigned
    result = _this1 = (reflaxe_i64_clamp = :erlang.band(value, 18446744073709551615)
if reflaxe_i64_clamp >= 9223372036854775808, do: reflaxe_i64_clamp - 18446744073709551616, else: reflaxe_i64_clamp)
    neg = Reflaxe.Elixir.HaxeFloat.lt(no_fractions, 0)
    rest = if (neg) do
      Reflaxe.Elixir.HaxeFloat.neg(no_fractions)
    else
      no_fractions
    end
    i = 0
    {result, _rest, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, rest, i}, fn _, {acc_result, acc_rest, acc_i} ->
      try do
        if (Reflaxe.Elixir.HaxeFloat.gte(acc_rest, 1)) do
          curr = Reflaxe.Elixir.HaxeFloat.remainder(acc_rest, 2)
          acc_rest = Reflaxe.Elixir.HaxeFloat.divide(acc_rest, 2)
          acc_result = (if (Reflaxe.Elixir.HaxeFloat.gte(curr, 1)) do
  int32_value = 1
  shift = 31
  x = :erlang.bsr(int32_value, shift)
  high = (reflaxe_i32_clamp = :erlang.band(x, 4294967295)
if reflaxe_i32_clamp >= 2147483648, do: reflaxe_i32_clamp - 4294967296, else: reflaxe_i32_clamp)
  low_unsigned = if int32_value < 0, do: int32_value + 4294967296, else: int32_value
  value = :erlang.bsl(high, 32) + low_unsigned
  a = _this1 = (reflaxe_i64_clamp = :erlang.band(value, 18446744073709551615)
if reflaxe_i64_clamp >= 9223372036854775808, do: reflaxe_i64_clamp - 18446744073709551616, else: reflaxe_i64_clamp)
  shift = Bitwise.band(acc_i, 63)
  v = :erlang.bsl(a, shift)
  b = _this1 = (reflaxe_i64_clamp = :erlang.band(v, 18446744073709551615)
if reflaxe_i64_clamp >= 9223372036854775808, do: reflaxe_i64_clamp - 18446744073709551616, else: reflaxe_i64_clamp)
  _this1 = (reflaxe_i64_clamp = :erlang.band(result + b, 18446744073709551615)
if reflaxe_i64_clamp >= 9223372036854775808, do: reflaxe_i64_clamp - 18446744073709551616, else: reflaxe_i64_clamp)
else
  acc_result
end)
          acc_i = acc_i + 1
          {:cont, {acc_result, acc_rest, acc_i}}
        else
          {:halt, {acc_result, acc_rest, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_result, acc_rest, acc_i}}
        :throw, :continue ->
          {:cont, {acc_result, acc_rest, acc_i}}
      end
    end)
    if (neg) do
      _this1 = (reflaxe_i64_clamp = :erlang.band(-result, 18446744073709551615)
if reflaxe_i64_clamp >= 9223372036854775808, do: reflaxe_i64_clamp - 18446744073709551616, else: reflaxe_i64_clamp)
    else
      result
    end
  end
end
