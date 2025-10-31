defmodule SourceMapTest do
  def simple_method(struct) do
    "test"
  end
  def conditional_method(struct, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = MyApp.SourceMapTest.new()
    result = test.simpleMethod()
    condition = test.conditionalMethod(42)
    Log.trace("Source mapping test: #{(fn -> result end).()} #{(fn -> inspect(condition) end).()}", %{:file_name => "SourceMapTest.hx", :line_number => 23, :class_name => "SourceMapTest", :method_name => "main"})
  end
end
