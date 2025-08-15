defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.testArrayFilterWithOuterVariable()
    Main.testArrayMapWithOuterVariable()
    Main.testNestedArrayOperations()
    Main.testMultipleOuterVariables()
  end

  @doc "Function test_array_filter_with_outer_variable"
  @spec test_array_filter_with_outer_variable() :: nil
  def test_array_filter_with_outer_variable() do
    items = ["apple", "banana", "cherry"]
    target_item = "banana"
    temp_array = nil
    _g = []
    _g = 0
    Enum.filter(items, fn item -> (item != target_item) end)
    temp_array = _g
    todos = [%{"id" => 1, "name" => "first"}, %{"id" => 2, "name" => "second"}]
    id = 2
    temp_array1 = nil
    _g = []
    _g = 0
    Enum.filter(todos, fn item -> (item.id != id) end)
    temp_array1 = _g
  end

  @doc "Function test_array_map_with_outer_variable"
  @spec test_array_map_with_outer_variable() :: nil
  def test_array_map_with_outer_variable() do
    numbers = [1, 2, 3, 4, 5]
    multiplier = 3
    temp_array = nil
    _g = []
    _g = 0
    Enum.map(numbers, fn item -> v = Enum.at(numbers, _g)
    _g = _g + 1
    _g ++ [v * multiplier] end)
    temp_array = _g
    prefix = "Item: "
    temp_array1 = nil
    _g = []
    _g = 0
    Enum.map(numbers, fn item -> v = Enum.at(numbers, _g)
    _g = _g + 1
    _g ++ [prefix <> Std.string(v)] end)
    temp_array1 = _g
  end

  @doc "Function test_nested_array_operations"
  @spec test_nested_array_operations() :: nil
  def test_nested_array_operations() do
    data = [[1, 2], [3, 4], [5, 6]]
    threshold = 3
    _g = []
    _g = 0
    Enum.map(data, fn temp_array1 -> v = Enum.at(data, _g)
    _g = _g + 1
    temp_array1 = nil
    _g = []
    _g = 0
    _g = v
    Enum.filter(_g, fn item -> (item > threshold) end)
    temp_array1 = _g
    _g ++ [temp_array1] end)
  end

  @doc "Function test_multiple_outer_variables"
  @spec test_multiple_outer_variables() :: nil
  def test_multiple_outer_variables() do
    items = ["a", "b", "c", "d"]
    prefix = "prefix_"
    suffix = "_suffix"
    exclude_item = "b"
    temp_array = nil
    temp_array1 = nil
    _g = []
    _g = 0
    Enum.filter(items, fn item -> (item != exclude_item) end)
    temp_array1 = _g
    _g = []
    _g = 0
    Enum.map(temp_array1, fn item -> v = Enum.at(temp_array1, _g)
    _g = _g + 1
    _g ++ [prefix <> v <> suffix] end)
    temp_array = _g
  end

end
