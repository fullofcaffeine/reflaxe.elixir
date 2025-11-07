defmodule Main do
  @import :Bitwise

  defp test_bitwise_and() do
    n = 255
    result1 = Bitwise.band(n, 15)
    _ = Log.trace("AND with literal: #{(fn -> result1 end).()}", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "testBitwiseAnd"})
    a = 255
    b = 15
    result2 = Bitwise.band(a, b)
    _ = Log.trace("AND with variables: #{(fn -> result2 end).()}", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testBitwiseAnd"})
    result3 = Bitwise.band(Bitwise.band(n, 240), 15)
    _ = Log.trace("AND chain: #{(fn -> result3 end).()}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testBitwiseAnd"})
  end
  defp test_bitwise_or() do
    flags = 0
    result1 = Bitwise.bor(flags, 1)
    _ = Log.trace("OR with literal: #{(fn -> result1 end).()}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testBitwiseOr"})
    read = 1
    write = 2
    result2 = Bitwise.bor(read, write)
    _ = Log.trace("OR flags: #{(fn -> result2 end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testBitwiseOr"})
    result3 = 15
    _ = Log.trace("OR chain: #{(fn -> result3 end).()}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testBitwiseOr"})
  end
  defp test_bitwise_xor() do
    x = 170
    y = 85
    result1 = Bitwise.bxor(x, y)
    _ = Log.trace("XOR: #{(fn -> result1 end).()}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "testBitwiseXor"})
    flag = true
    toggle = if (flag), do: 1, else: 0
    result2 = Bitwise.bxor(toggle, 1)
    _ = Log.trace("XOR toggle: #{(fn -> result2 end).()}", %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "testBitwiseXor"})
  end
  defp test_shift_left() do
    value = 1
    result1 = Bitwise.bsl(value, 4)
    _ = Log.trace("Shift left: #{(fn -> result1 end).()}", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "testShiftLeft"})
    result2 = 256
    _ = Log.trace("Shift power: #{(fn -> result2 end).()}", %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "testShiftLeft"})
    shift_by = 3
    result3 = Bitwise.bsl(value, shift_by)
    _ = Log.trace("Variable shift: #{(fn -> result3 end).()}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testShiftLeft"})
  end
  defp test_shift_right() do
    value = 256
    result1 = Bitwise.bsr(value, 4)
    _ = Log.trace("Shift right: #{(fn -> result1 end).()}", %{:file_name => "Main.hx", :line_number => 115, :class_name => "Main", :method_name => "testShiftRight"})
    result2 = 256
    _ = Log.trace("Shift divide: #{(fn -> result2 end).()}", %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "testShiftRight"})
    shift_by = 3
    result3 = Bitwise.bsr(value, shift_by)
    _ = Log.trace("Variable shift: #{(fn -> result3 end).()}", %{:file_name => "Main.hx", :line_number => 124, :class_name => "Main", :method_name => "testShiftRight"})
  end
  defp test_nested_operations() do
    n = 43981
    high_nibble = Bitwise.band(Bitwise.bsr(n, 12), 15)
    _ = Log.trace("High nibble: #{(fn -> high_nibble end).()}", %{:file_name => "Main.hx", :line_number => 136, :class_name => "Main", :method_name => "testNestedOperations"})
    result = Bitwise.bor(Bitwise.bsl(Bitwise.band(n, 255), 8), Bitwise.band(Bitwise.bsr(n, 8), 255))
    _ = Log.trace("Byte swap: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "testNestedOperations"})
    masked = Bitwise.bor(Bitwise.band(n, 65280), Bitwise.band(n, 255))
    _ = Log.trace("Complex mask: #{(fn -> masked end).()}", %{:file_name => "Main.hx", :line_number => 144, :class_name => "Main", :method_name => "testNestedOperations"})
  end
  defp test_operator_precedence() do
    a = 240
    b = 15
    c = 8
    result1 = Bitwise.bor(Bitwise.band(a, b), c)
    _ = Log.trace("AND before OR: #{(fn -> result1 end).()}", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testOperatorPrecedence"})
    result2 = Bitwise.band(a, Bitwise.bor(b, c))
    _ = Log.trace("OR before AND: #{(fn -> result2 end).()}", %{:file_name => "Main.hx", :line_number => 162, :class_name => "Main", :method_name => "testOperatorPrecedence"})
    result3 = Bitwise.band(Bitwise.bsl(a, 2), 255)
    _ = Log.trace("Shift before AND: #{(fn -> result3 end).()}", %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "testOperatorPrecedence"})
  end
  defp test_complex_expressions() do
    n = 255
    hex_chars = "0123456789ABCDEF"
    s = ""
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s}, (fn -> fn _, {n, s} ->
  if (n > 0) do
    digit = Bitwise.band(n, 15)
    s = String.at(hex_chars, digit) || "" <> s
    n = Bitwise.bsr(n, 4)
    {:cont, {n, s}}
  else
    {:halt, {n, s}}
  end
end end).())
    _ = Log.trace("Hex string: #{(fn -> s end).()}", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "testComplexExpressions"})
    r = 255
    b = 64
    rgb = Bitwise.bor(Bitwise.bor(Bitwise.bsl(r, 16), Bitwise.bsl(128, 8)), b)
    _ = Log.trace("RGB packed: #{(fn -> rgb end).()}", %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "testComplexExpressions"})
    extracted_r = Bitwise.band(Bitwise.bsr(rgb, 16), 255)
    extracted_g = Bitwise.band(Bitwise.bsr(rgb, 8), 255)
    extracted_b = Bitwise.band(rgb, 255)
    _ = Log.trace("RGB extracted: #{(fn -> extracted_r end).()}, #{(fn -> extracted_g end).()}, #{(fn -> extracted_b end).()}", %{:file_name => "Main.hx", :line_number => 197, :class_name => "Main", :method_name => "testComplexExpressions"})
  end
end
