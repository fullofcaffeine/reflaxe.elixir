defmodule SourceMapTest do
  def new() do
    %{:__reflaxe_class__ => SourceMapTest}
  end
  def simple_method(_) do
    "test"
  end
  def conditional_method(_, value) do
    if (value > 0), do: true, else: false
  end
  def main() do
    test = SourceMapTest.new()
    _result = apply(Map.get(test, :__reflaxe_class__) || Map.get(test, :__struct__), :simple_method, [test])
    _condition = apply(Map.get(test, :__reflaxe_class__) || Map.get(test, :__struct__), :conditional_method, [test, 42])
    nil
  end
end
