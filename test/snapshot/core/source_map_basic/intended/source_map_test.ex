defmodule SourceMapTest do
  def simple_method(_struct) do
    "test"
  end
  def conditional_method(_struct, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = MyApp.SourceMapTest.new()
    result = test.simpleMethod()
    condition = test.conditionalMethod(42)
    nil
  end
end
