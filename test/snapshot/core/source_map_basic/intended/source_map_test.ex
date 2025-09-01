defmodule SourceMapTest do
  def new() do
    %{}
  end
  def simple_method(struct) do
    "test"
  end
  def conditional_method(struct, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = SourceMapTest.new()
    result = test.simpleMethod()
    condition = test.conditionalMethod(42)
    Log.trace("Source mapping test: " + result + " " + Std.string(condition), %{:fileName => "SourceMapTest.hx", :lineNumber => 23, :className => "SourceMapTest", :methodName => "main"})
  end
end