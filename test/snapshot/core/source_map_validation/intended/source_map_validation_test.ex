defmodule SourceMapValidationTest do
  def main() do
    _ = Log.trace("=== Source Map Validation Test ===", %{:file_name => "SourceMapValidationTest.hx", :line_number => 13, :class_name => "SourceMapValidationTest", :method_name => "main"})
    simple_var = "test"
    number = 42
    _ = test_function(simple_var, number)
    if (number > 0) do
      Log.trace("Positive number", %{:file_name => "SourceMapValidationTest.hx", :line_number => 24, :class_name => "SourceMapValidationTest", :method_name => "main"})
    else
      Log.trace("Non-positive number", %{:file_name => "SourceMapValidationTest.hx", :line_number => 26, :class_name => "SourceMapValidationTest", :method_name => "main"})
    end
    _ = Log.trace("Loop iteration: #{(fn -> 0 end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    _ = Log.trace("Loop iteration: #{(fn -> 1 end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    _ = Log.trace("Loop iteration: #{(fn -> 2 end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    _ = Log.trace("Loop iteration: #{(fn -> 3 end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    _ = Log.trace("Loop iteration: #{(fn -> 4 end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"})
    array = [1, 2, 3, 4, 5]
    _ = Enum.each(array, (fn -> fn item ->
    process_item(item)
end end).())
    obj_name = "Test"
    obj_value = 100
    obj_nested_field = "nested value"
    instance = MyApp.TestClass.new("example")
    _ = instance.doSomething()
    _ = Log.trace("=== Test Complete ===", %{:file_name => "SourceMapValidationTest.hx", :line_number => 53, :class_name => "SourceMapValidationTest", :method_name => "main"})
  end
  defp test_function(str, num) do
    Log.trace("Testing with: #{(fn -> str end).()} and #{(fn -> num end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 57, :class_name => "SourceMapValidationTest", :method_name => "testFunction"})
  end
  defp process_item(item) do
    Log.trace("Processing item: #{(fn -> item end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 61, :class_name => "SourceMapValidationTest", :method_name => "processItem"})
  end
end
