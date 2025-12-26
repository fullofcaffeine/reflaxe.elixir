defmodule SourceMapValidationTest do
  def main() do
    simple_var = "test"
    number = 42
    _ = test_function(simple_var, number)
    if (number > 0), do: nil, else: nil
    array = [1, 2, 3, 4, 5]
    _g = 0
    _ = Enum.each(array, fn item -> process_item(item) end)
    _ = nil
    _ = nil
    _ = nil
    obj_name = "Test"
    obj_value = 100
    obj_nested_field = "nested value"
    instance = MyApp.TestClass.new("example")
    _ = instance.doSomething()
    nil
  end
  defp test_function(str, num) do
    nil
  end
  defp process_item(item) do
    nil
  end
end
