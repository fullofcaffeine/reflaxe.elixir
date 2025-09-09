defmodule Main do
  def main() do
    test_string_conversion()
    test_parsing()
    test_type_checking()
    test_random_and_int()
  end
  defp test_string_conversion() do
    int_str = "42"
    float_str = Std.string(3.14)
    bool_str = "true"
    null_str = Std.string(nil)
    obj = %{:name => "test", :value => 123}
    obj_str = Std.string(obj)
    arr = [1, 2, 3]
    arr_str = Std.string(arr)
    option = {:Some, "value"}
    option_str = Std.string(option)
    Log.trace("String conversions:", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Int: " <> int_str, %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Float: " <> float_str, %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Bool: " <> bool_str, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Null: " <> null_str, %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Object: " <> obj_str, %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Array: " <> arr_str, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testStringConversion"})
    Log.trace("  Enum: " <> option_str, %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testStringConversion"})
  end
  defp test_parsing() do
    valid_int = Std.parse_int("42")
    negative_int = Std.parse_int("-123")
    invalid_int = Std.parse_int("abc")
    partial_int = Std.parse_int("42abc")
    empty_int = Std.parse_int("")
    valid_float = Std.parse_float("3.14")
    negative_float = Std.parse_float("-2.5")
    int_as_float = Std.parse_float("42")
    invalid_float = Std.parse_float("xyz")
    partial_float = Std.parse_float("3.14xyz")
    Log.trace("Integer parsing:", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Valid: " <> Kernel.to_string(valid_int), %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Negative: " <> Kernel.to_string(negative_int), %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Invalid: " <> Kernel.to_string(invalid_int), %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Partial: " <> Kernel.to_string(partial_int), %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Empty: " <> Kernel.to_string(empty_int), %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("Float parsing:", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Valid: " <> Kernel.to_string(valid_float), %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Negative: " <> Kernel.to_string(negative_float), %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Int as float: " <> Kernel.to_string(int_as_float), %{:file_name => "Main.hx", :line_number => 67, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Invalid: " <> Kernel.to_string(invalid_float), %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "testParsing"})
    Log.trace("  Partial: " <> Kernel.to_string(partial_float), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testParsing"})
  end
  defp test_type_checking() do
    str = "hello"
    _num = 42
    _float = 3.14
    _bool = true
    arr = [1, 2, 3]
    obj_field = nil
    obj_field = "value"
    str_is_string = Std.is(str, String)
    arr_is_array = Std.is(arr, Array)
    Log.trace("Type checking with Std.is():", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "testTypeChecking"})
    Log.trace("  String is String: " <> Std.string(str_is_string), %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testTypeChecking"})
    Log.trace("  Array is Array: " <> Std.string(arr_is_array), %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testTypeChecking"})
    Log.trace("  Note: Abstract type checks (Int/Float/Bool) commented out", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testTypeChecking"})
    Log.trace("  These require special handling in the Elixir compiler", %{:file_name => "Main.hx", :line_number => 106, :class_name => "Main", :method_name => "testTypeChecking"})
  end
  defp test_random_and_int() do
    rand1 = Std.random()
    rand2 = Std.random()
    rand3 = Std.random()
    truncated1 = 3
    truncated2 = 3
    truncated3 = -2
    truncated4 = -2
    truncated5 = 0
    Log.trace("Random numbers (0-1):", %{:file_name => "Main.hx", :line_number => 125, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  Random 1: " <> Kernel.to_string(rand1), %{:file_name => "Main.hx", :line_number => 126, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  Random 2: " <> Kernel.to_string(rand2), %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  Random 3: " <> Kernel.to_string(rand3), %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("Float truncation with Std.int():", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  3.14 -> " <> Kernel.to_string(truncated1), %{:file_name => "Main.hx", :line_number => 131, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  3.99 -> " <> Kernel.to_string(truncated2), %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  -2.5 -> " <> Kernel.to_string(truncated3), %{:file_name => "Main.hx", :line_number => 133, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  -2.1 -> " <> Kernel.to_string(truncated4), %{:file_name => "Main.hx", :line_number => 134, :class_name => "Main", :method_name => "testRandomAndInt"})
    Log.trace("  0.0 -> " <> Kernel.to_string(truncated5), %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testRandomAndInt"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()