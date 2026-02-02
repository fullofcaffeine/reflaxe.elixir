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
    if (f != f or not f == f and f != 1.79769313486231571e+308 and f != -1.79769313486231571e+308) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Number is NaN or Infinite"]
    end
    no_fractions = (f - rem(f, 1))
    if (no_fractions > 9007199254740991) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conversion overflow"]
    end
    if (no_fractions < -9007199254740991) do
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
    neg = no_fractions < 0
    rest = if (neg) do
      -no_fractions
    else
      no_fractions
    end
    i = 0
    {result, _rest, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, rest, i}, fn _, {acc_result, acc_rest, acc_i} ->
      try do
        if (acc_rest >= 1) do
          _curr = rem(acc_rest, 2)
          acc_rest = acc_rest / 2
          _old_i = acc_i
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
