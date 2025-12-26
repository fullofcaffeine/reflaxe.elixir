defmodule SourceMapTest do
  def simple_method(struct) do
    "test"
  end
  def conditional_method(struct, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = %SourceMapTest{}
    result = test.simpleMethod()
    condition = test.conditionalMethod(42)
    nil
  end
end
