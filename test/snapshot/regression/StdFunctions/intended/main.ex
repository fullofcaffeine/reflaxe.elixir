defmodule Main do
  def main() do
    _ = test_string_conversion()
    _ = test_parsing()
    _ = test_type_checking()
    _ = test_random_and_int()
  end
  defp test_string_conversion() do
    int_str = "42"
    float_str = inspect(3.14)
    bool_str = "true"
    null_str = inspect(nil)
    obj = %{:name => "test", :value => 123}
    obj_str = inspect(obj)
    arr = [1, 2, 3]
    arr_str = inspect(arr)
    option = {:some, "value"}
    option_str = inspect(option)
    _ = Log.trace("String conversions:", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Int: #{(fn -> int_str end).()}", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Float: #{(fn -> float_str end).()}", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Bool: #{(fn -> bool_str end).()}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Null: #{(fn -> null_str end).()}", %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Object: #{(fn -> obj_str end).()}", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Array: #{(fn -> arr_str end).()}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testStringConversion"})
    _ = Log.trace("  Enum: #{(fn -> option_str end).()}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testStringConversion"})
  end
  defp test_parsing() do
    valid_int = String.to_integer("42")
    negative_int = String.to_integer("-123")
    invalid_int = String.to_integer("abc")
    partial_int = String.to_integer("42abc")
    empty_int = String.to_integer("")
    valid_float = String.to_float("3.14")
    negative_float = String.to_float("-2.5")
    int_as_float = String.to_float("42")
    invalid_float = String.to_float("xyz")
    partial_float = String.to_float("3.14xyz")
    _ = Log.trace("Integer parsing:", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Valid: #{(fn -> valid_int end).()}", %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Negative: #{(fn -> negative_int end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Invalid: #{(fn -> invalid_int end).()}", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Partial: #{(fn -> partial_int end).()}", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Empty: #{(fn -> empty_int end).()}", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("Float parsing:", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Valid: #{(fn -> valid_float end).()}", %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Negative: #{(fn -> negative_float end).()}", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Int as float: #{(fn -> int_as_float end).()}", %{:file_name => "Main.hx", :line_number => 67, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Invalid: #{(fn -> invalid_float end).()}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "testParsing"})
    _ = Log.trace("  Partial: #{(fn -> partial_float end).()}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testParsing"})
  end
  defp test_type_checking() do
    str = "hello"
    num = 42
    float = 3.14
    bool = true
    arr = [1, 2, 3]
    obj_field = "value"
    str_is_string = str_is_string.(str)
    arr_is_array = str_is_string.(arr)
    _ = Log.trace("Type checking with Std.is():", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "testTypeChecking"})
    _ = Log.trace("  String is String: #{(fn -> inspect(str_is_string) end).()}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testTypeChecking"})
    _ = Log.trace("  Array is Array: #{(fn -> inspect(arr_is_array) end).()}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testTypeChecking"})
    _ = Log.trace("  Note: Abstract type checks (Int/Float/Bool) commented out", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testTypeChecking"})
    _ = Log.trace("  These require special handling in the Elixir compiler", %{:file_name => "Main.hx", :line_number => 106, :class_name => "Main", :method_name => "testTypeChecking"})
  end
  defp test_random_and_int() do
    rand1 = MyApp.Std.random()
    rand2 = MyApp.Std.random()
    rand3 = MyApp.Std.random()
    truncated1 = 3
    truncated2 = 3
    truncated3 = -2
    truncated4 = -2
    truncated5 = 0
    _ = Log.trace("Random numbers (0-1):", %{:file_name => "Main.hx", :line_number => 125, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  Random 1: #{(fn -> rand1 end).()}", %{:file_name => "Main.hx", :line_number => 126, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  Random 2: #{(fn -> rand2 end).()}", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  Random 3: #{(fn -> rand3 end).()}", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("Float truncation with Std.int():", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  3.14 -> #{(fn -> truncated1 end).()}", %{:file_name => "Main.hx", :line_number => 131, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  3.99 -> #{(fn -> truncated2 end).()}", %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  -2.5 -> #{(fn -> truncated3 end).()}", %{:file_name => "Main.hx", :line_number => 133, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  -2.1 -> #{(fn -> truncated4 end).()}", %{:file_name => "Main.hx", :line_number => 134, :class_name => "Main", :method_name => "testRandomAndInt"})
    _ = Log.trace("  0.0 -> #{(fn -> truncated5 end).()}", %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testRandomAndInt"})
  end
end
