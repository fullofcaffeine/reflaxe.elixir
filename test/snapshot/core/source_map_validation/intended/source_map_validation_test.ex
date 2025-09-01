defmodule SourceMapValidationTest do
  def main() do
    Log.trace("=== Source Map Validation Test ===", %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 13, :className => "SourceMapValidationTest", :methodName => "main"})
    simple_var = "test"
    number = 42
    SourceMapValidationTest.test_function(simple_var, number)
    if (number > 0) do
      Log.trace("Positive number", %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 24, :className => "SourceMapValidationTest", :methodName => "main"})
    else
      Log.trace("Non-positive number", %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 26, :className => "SourceMapValidationTest", :methodName => "main"})
    end
    Log.trace("Loop iteration: " + 0, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 31, :className => "SourceMapValidationTest", :methodName => "main"})
    Log.trace("Loop iteration: " + 1, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 31, :className => "SourceMapValidationTest", :methodName => "main"})
    Log.trace("Loop iteration: " + 2, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 31, :className => "SourceMapValidationTest", :methodName => "main"})
    Log.trace("Loop iteration: " + 3, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 31, :className => "SourceMapValidationTest", :methodName => "main"})
    Log.trace("Loop iteration: " + 4, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 31, :className => "SourceMapValidationTest", :methodName => "main"})
    array = [1, 2, 3, 4, 5]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < array.length) do
  item = array[g]
  g + 1
  SourceMapValidationTest.process_item(item)
  {:cont, acc}
else
  {:halt, acc}
end end)
    obj_value = nil
    obj_nested_field = nil
    obj_name = nil
    obj_name = "Test"
    obj_value = 100
    obj_nested_field = "nested value"
    instance = TestClass.new("example")
    instance.doSomething()
    Log.trace("=== Test Complete ===", %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 53, :className => "SourceMapValidationTest", :methodName => "main"})
  end
  defp test_function(str, num) do
    Log.trace("Testing with: " + str + " and " + num, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 57, :className => "SourceMapValidationTest", :methodName => "testFunction"})
  end
  defp process_item(item) do
    Log.trace("Processing item: " + item, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 61, :className => "SourceMapValidationTest", :methodName => "processItem"})
  end
end