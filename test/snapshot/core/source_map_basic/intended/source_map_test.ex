defmodule SourceMapTest do
  def simple_method(struct) do
    "test"
  end
  def conditional_method(struct, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = %SourceMapTest{}
    result = simple_method(test)
    condition = conditional_method(test, 42)
    nil
  end
end
