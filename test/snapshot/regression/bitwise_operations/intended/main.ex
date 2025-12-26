defmodule Main do
  @import :Bitwise

  defp test_bitwise_and() do
    n = 255
    result1 = Bitwise.band(n, 15)
    a = 255
    b = 15
    result2 = Bitwise.band(a, b)
    result3 = Bitwise.band(Bitwise.band(n, 240), 15)
    nil
  end
  defp test_bitwise_or() do
    flags = 0
    result1 = Bitwise.bor(flags, 1)
    read = 1
    write = 2
    result2 = Bitwise.bor(read, write)
    _ = 15
    nil
  end
  defp test_bitwise_xor() do
    x = 170
    y = 85
    result1 = Bitwise.bxor(x, y)
    flag = true
    toggle = if (flag), do: 1, else: 0
    result2 = Bitwise.bxor(toggle, 1)
    nil
  end
  defp test_shift_left() do
    value = 1
    result1 = Bitwise.bsl(value, 4)
    _ = 256
    shift_by = 3
    result3 = Bitwise.bsl(value, shift_by)
    nil
  end
  defp test_shift_right() do
    value = 256
    result1 = Bitwise.bsr(value, 4)
    _ = 256
    shift_by = 3
    result3 = Bitwise.bsr(value, shift_by)
    nil
  end
  defp test_nested_operations() do
    n = 43981
    high_nibble = Bitwise.band(Bitwise.bsr(n, 12), 15)
    result = Bitwise.bor(Bitwise.bsl(Bitwise.band(n, 255), 8), Bitwise.band(Bitwise.bsr(n, 8), 255))
    masked = Bitwise.bor(Bitwise.band(n, 65280), Bitwise.band(n, 255))
    nil
  end
  defp test_operator_precedence() do
    a = 240
    b = 15
    c = 8
    result1 = Bitwise.bor(Bitwise.band(a, b), c)
    result2 = Bitwise.band(a, Bitwise.bor(b, c))
    result3 = Bitwise.band(Bitwise.bsl(a, 2), 255)
    nil
  end
  defp test_complex_expressions() do
    n = 255
    hex_chars = "0123456789ABCDEF"
    s = ""
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s}, fn _, {n, s} ->
      if (n > 0) do
        digit = Bitwise.band(n, 15)
        s = String.at(hex_chars, digit) || "" <> s
        n = Bitwise.bsr(n, 4)
        {:cont, {n, s}}
      else
        {:halt, {n, s}}
      end
    end)
    nil
    r = 255
    b = 64
    rgb = Bitwise.bor(Bitwise.bor(Bitwise.bsl(r, 16), Bitwise.bsl(128, 8)), b)
    extracted_r = Bitwise.band(Bitwise.bsr(rgb, 16), 255)
    extracted_g = Bitwise.band(Bitwise.bsr(rgb, 8), 255)
    extracted_b = Bitwise.band(rgb, 255)
    nil
  end
end
