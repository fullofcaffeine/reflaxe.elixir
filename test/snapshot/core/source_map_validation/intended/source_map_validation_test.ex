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
    Enum.each(0..4, fn item -> Log.trace("Loop iteration: #{(fn -> k end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 31, :class_name => "SourceMapValidationTest", :method_name => "main"}) end)
    array = [1, 2, 3, 4, 5]
    Enum.each(array, fn item ->
            process_item(item)
    end)
    _ = "Test"
    _ = 100
    _ = "nested value"
    instance = MyApp.TestClass.new("example")
    instance.doSomething()
    Log.trace("=== Test Complete ===", %{:file_name => "SourceMapValidationTest.hx", :line_number => 53, :class_name => "SourceMapValidationTest", :method_name => "main"})
  end
  defp test_function(str, num) do
    Log.trace("Testing with: #{(fn -> str end).()} and #{(fn -> num end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 57, :class_name => "SourceMapValidationTest", :method_name => "testFunction"})
  end
  defp process_item(item) do
    Log.trace("Processing item: #{(fn -> item end).()}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 61, :class_name => "SourceMapValidationTest", :method_name => "processItem"})
  end
end
