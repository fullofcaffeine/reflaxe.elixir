defmodule SourceMapValidationTest do
  def main() do
    Log.trace("=== Source Map Validation Test ===", %{:file_name => "SourceMapValidationTest.hx", :line_number => 13, :class_name => "SourceMapValidationTest", :method_name => "main"})
    simple_var = "test"
    number = 42
    test_function(simple_var, number)
    if (number > 0) do
      Log.trace("Positive number", %{:file_name => "SourceMapValidationTest.hx", :line_number => 24, :class_name => "SourceMapValidationTest", :method_name => "main"})
    else
      Log.trace("Non-positive number", %{:file_name => "SourceMapValidationTest.hx", :line_number => 26, :class_name => "SourceMapValidationTest", :method_name => "main"})
    end
    Log.trace("Loop iteration: " <> Kernel.to_string(0), %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    Log.trace("Loop iteration: " <> Kernel.to_string(1), %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    Log.trace("Loop iteration: " <> Kernel.to_string(2), %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    Log.trace("Loop iteration: " <> Kernel.to_string(3), %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    Log.trace("Loop iteration: " <> Kernel.to_string(4), %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    array = [1, 2, 3, 4, 5]
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {array}, fn _, {array} ->
  if (0 < length(array)) do
    item = array[0]
    0 + 1
    process_item(item)
    {:cont, {array}}
  else
    {:halt, {array}}
  end
end)
    obj_name = "Test"
    obj_value = 100
    obj_nested_field = "nested value"
    instance = TestClass.new("example")
    instance.do_something()
    Log.trace("=== Test Complete ===", %{:file_name => "SourceMapValidationTest.hx", :line_number => 53, :class_name => "SourceMapValidationTest", :method_name => "main"})
  end
  defp test_function(str, num) do
    Log.trace("Testing with: " <> str <> " and " <> Kernel.to_string(num), %{:file_name => "SourceMapValidationTest.hx", :line_number => 57, :class_name => "SourceMapValidationTest", :method_name => "testFunction"})
  end
  defp process_item(item) do
    Log.trace("Processing item: " <> Kernel.to_string(item), %{:file_name => "SourceMapValidationTest.hx", :line_number => 61, :class_name => "SourceMapValidationTest", :method_name => "processItem"})
  end
end