defmodule Main do
  def main() do
    _ = test_bitwise_and()
    _ = test_bitwise_or()
    _ = test_bitwise_xor()
    _ = test_shift_left()
    _ = test_shift_right()
    _ = test_nested_operations()
    _ = test_operator_precedence()
    _ = test_complex_expressions()
  end
  defp test_bitwise_and() do
    n = 255
    _result1 = Bitwise.band(n, 15)
    a = 255
    b = 15
    _result2 = Bitwise.band(a, b)
    _result3 = Bitwise.band(Bitwise.band(n, 240), 15)
    nil
  end
  defp test_bitwise_or() do
    flags = 0
    _result1 = Bitwise.bor(flags, 1)
    read = 1
    write = 2
    _result2 = Bitwise.bor(read, write)
    _ = 15
    nil
  end
  defp test_bitwise_xor() do
    x = 170
    y = 85
    _result1 = Bitwise.bxor(x, y)
    flag = true
    toggle = if (flag), do: 1, else: 0
    _result2 = Bitwise.bxor(toggle, 1)
    nil
  end
  defp test_shift_left() do
    value = 1
    _result1 = Bitwise.bsl(value, 4)
    _ = 256
    shift_by = 3
    _result3 = Bitwise.bsl(value, shift_by)
    nil
  end
  defp test_shift_right() do
    value = 256
    _result1 = Bitwise.bsr(value, 4)
    _ = 256
    shift_by = 3
    _result3 = Bitwise.bsr(value, shift_by)
    nil
  end
  defp test_nested_operations() do
    n = 43981
    _high_nibble = Bitwise.band(Bitwise.bsr(n, 12), 15)
    _result = Bitwise.bor(Bitwise.bsl(Bitwise.band(n, 255), 8), Bitwise.band(Bitwise.bsr(n, 8), 255))
    _masked = Bitwise.bor(Bitwise.band(n, 65280), Bitwise.band(n, 255))
    nil
  end
  defp test_operator_precedence() do
    a = 240
    b = 15
    c = 8
    _result1 = Bitwise.bor(Bitwise.band(a, b), c)
    _result2 = Bitwise.band(a, Bitwise.bor(b, c))
    _result3 = Bitwise.band(Bitwise.bsl(a, 2), 255)
    nil
  end
  defp test_complex_expressions() do
    n = 255
    s = ""
    {_n, _s} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s}, fn _, {acc_n, acc_s} ->
      try do
        if (acc_n > 0) do
          digit = Bitwise.band(acc_n, 15)
          acc_s = (if (digit < 0) do
  ""
else
  String.at(hex_chars, digit) || ""
end) <> acc_s
          acc_n = Bitwise.bsr(acc_n, 4)
          {:cont, {acc_n, acc_s}}
        else
          {:halt, {acc_n, acc_s}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_n, acc_s}}
        :throw, :continue ->
          {:cont, {acc_n, acc_s}}
      end
    end)
    r = 255
    b = 64
    rgb = Bitwise.bor(Bitwise.bor(Bitwise.bsl(r, 16), Bitwise.bsl(128, 8)), b)
    _extracted_r = Bitwise.band(Bitwise.bsr(rgb, 16), 255)
    _extracted_g = Bitwise.band(Bitwise.bsr(rgb, 8), 255)
    _extracted_b = Bitwise.band(rgb, 255)
    nil
  end
end
