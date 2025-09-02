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
    Log.trace("String conversions:", %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Int: " <> int_str, %{:fileName => "Main.hx", :lineNumber => 33, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Float: " <> float_str, %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Bool: " <> bool_str, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Null: " <> null_str, %{:fileName => "Main.hx", :lineNumber => 36, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Object: " <> obj_str, %{:fileName => "Main.hx", :lineNumber => 37, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Array: " <> arr_str, %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "testStringConversion"})
    Log.trace("  Enum: " <> option_str, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "testStringConversion"})
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
    Log.trace("Integer parsing:", %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Valid: " <> valid_int, %{:fileName => "Main.hx", :lineNumber => 58, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Negative: " <> negative_int, %{:fileName => "Main.hx", :lineNumber => 59, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Invalid: " <> invalid_int, %{:fileName => "Main.hx", :lineNumber => 60, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Partial: " <> partial_int, %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Empty: " <> empty_int, %{:fileName => "Main.hx", :lineNumber => 62, :className => "Main", :methodName => "testParsing"})
    Log.trace("Float parsing:", %{:fileName => "Main.hx", :lineNumber => 64, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Valid: " <> valid_float, %{:fileName => "Main.hx", :lineNumber => 65, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Negative: " <> negative_float, %{:fileName => "Main.hx", :lineNumber => 66, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Int as float: " <> int_as_float, %{:fileName => "Main.hx", :lineNumber => 67, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Invalid: " <> invalid_float, %{:fileName => "Main.hx", :lineNumber => 68, :className => "Main", :methodName => "testParsing"})
    Log.trace("  Partial: " <> partial_float, %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "testParsing"})
  end
  defp test_type_checking() do
    str = "hello"
    num = 42
    float = 3.14
    bool = true
    arr = [1, 2, 3]
    obj_field = nil
    obj_field = "value"
    str_is_string = Std.is(str, String)
    arr_is_array = Std.is(arr, Array)
    Log.trace("Type checking with Std.is():", %{:fileName => "Main.hx", :lineNumber => 102, :className => "Main", :methodName => "testTypeChecking"})
    Log.trace("  String is String: " <> Std.string(str_is_string), %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testTypeChecking"})
    Log.trace("  Array is Array: " <> Std.string(arr_is_array), %{:fileName => "Main.hx", :lineNumber => 104, :className => "Main", :methodName => "testTypeChecking"})
    Log.trace("  Note: Abstract type checks (Int/Float/Bool) commented out", %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "testTypeChecking"})
    Log.trace("  These require special handling in the Elixir compiler", %{:fileName => "Main.hx", :lineNumber => 106, :className => "Main", :methodName => "testTypeChecking"})
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
    Log.trace("Random numbers (0-1):", %{:fileName => "Main.hx", :lineNumber => 125, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  Random 1: " <> rand, %{:fileName => "Main.hx", :lineNumber => 126, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  Random 2: " <> rand, %{:fileName => "Main.hx", :lineNumber => 127, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  Random 3: " <> rand, %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("Float truncation with Std.int():", %{:fileName => "Main.hx", :lineNumber => 130, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  3.14 -> " <> truncated, %{:fileName => "Main.hx", :lineNumber => 131, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  3.99 -> " <> truncated, %{:fileName => "Main.hx", :lineNumber => 132, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  -2.5 -> " <> truncated, %{:fileName => "Main.hx", :lineNumber => 133, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  -2.1 -> " <> truncated, %{:fileName => "Main.hx", :lineNumber => 134, :className => "Main", :methodName => "testRandomAndInt"})
    Log.trace("  0.0 -> " <> truncated, %{:fileName => "Main.hx", :lineNumber => 135, :className => "Main", :methodName => "testRandomAndInt"})
  end
end