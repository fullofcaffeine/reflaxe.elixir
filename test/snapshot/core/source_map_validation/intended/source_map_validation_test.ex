defmodule SourceMapValidationTest do
  def main() do
    simple_var = "test"
    number = 42
    _ = test_function(simple_var, number)
    if (number > 0), do: nil, else: nil
    array = [1, 2, 3, 4, 5]
    _g = 0
    _ = Enum.each(array, fn item -> process_item(item) end)
    instance = TestClass.new("example")
    _ = TestClass.do_something(instance)
    nil
  end
  defp test_function(_, _) do
    nil
  end
  defp process_item(_) do
    nil
  end
end
