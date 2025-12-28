defmodule SourceMapTest do
  def new() do
    %{}
  end
  def simple_method(_) do
    "test"
  end
  def conditional_method(_, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = %SourceMapTest{}
    _result = simple_method(test)
    _condition = conditional_method(test, 42)
    nil
  end
end
