defmodule Main do
  def simple_nested() do
    [(fn ->
  _g = g ++ [2]
  []
end).(), (fn ->
  _g = g ++ [5]
  []
end).(), (fn ->
  _g = g ++ [8]
  []
end).()]
  end
  def constant_range_unrolled() do
    [(fn ->
  _g = g ++ [1]
  []
end).(), (fn ->
  _g = g ++ [1]
  []
end).()]
  end
  def nested_with_condition() do
    [(fn ->
  g ++ [0]
  g ++ [2]
  []
end).(), (fn ->
  g ++ [5]
  g ++ [7]
  []
end).(), (fn ->
  g ++ [8]
  g ++ [10]
  []
end).(), (fn ->
  g ++ [13]
  g ++ [15]
  []
end).()]
  end
  def deeply_nested() do
    [(fn ->
  _g = g ++ [(fn ->
  _g = g ++ [3]
  []
end).()]
  []
end).(), (fn ->
  _g = g ++ [(fn ->
  _g = g ++ [7]
  []
end).()]
  []
end).()]
  end
  def four_level_nesting() do
    [(fn ->
  _g = g ++ [(fn ->
  _g = g ++ [(fn ->
  _g = g ++ [7]
  []
end).()]
  []
end).()]
  []
end).(), (fn ->
  _g = g ++ [(fn ->
  _g = g ++ [(fn ->
  _g = g ++ [15]
  []
end).()]
  []
end).()]
  []
end).()]
  end
  def nested_with_expression() do
    [(fn ->
  _g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(2)]
  []
end).(), (fn ->
  _g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(2)]
  []
end).(), (fn ->
  _g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(2)]
  []
end).()]
  end
  def nested_with_block() do
    [(fn ->
  temp = 0
  _g = g ++ [temp]
  temp = 0
  _g = g ++ [temp + 1]
  temp = 0
  _g = g ++ [temp + 2]
  []
end).(), (fn ->
  temp = 0
  _g = g ++ [temp + 1]
  temp = 1
  _g = g ++ [temp + 2]
  temp = 2
  _g = g ++ [temp + 3]
  []
end).(), (fn ->
  temp = 0
  _g = g ++ [temp + 2]
  temp = 2
  _g = g ++ [temp + 3]
  temp = 4
  _g = g ++ [temp + 4]
  []
end).()]
  end
  def mixed_constant_variable() do
    n = 3
    g = []
    g_value = 0
    _g = Enum.reduce(0..(g - 1)//1, g, fn i, g_acc ->
      Enum.concat(g_acc, (fn -> [(fn ->
  _g = Enum.concat(g_acc, [i + 1])
  []
end).()] end).())
    end)
    g
  end
  def nested_in_expression() do
    sum = 0
    [(fn ->
  [0]
  [1]
  [2]
  []
end).()]
    [(fn ->
  [1]
  [2]
  [3]
  []
end).()]
    [(fn ->
  [2]
  [3]
  [4]
  []
end).()]
    data = []
    _g = 0
    sum = Enum.reduce(data, sum, fn row, sum_acc ->
      _g = 0
      Enum.reduce(row, sum_acc, fn val, sum_acc -> sum_acc + val end)
    end)
    sum
  end
  def with_meta_and_parens() do
    [(fn ->
  _g = g ++ [1]
  []
end).(), (fn ->
  _g = g ++ [3]
  []
end).()]
  end
  def mixed_with_literals() do
    [(fn ->
  _g = g ++ [4]
  []
end).(), [10, 20, 30], (fn ->
  _g = g ++ [102]
  []
end).()]
  end
  def comprehension_from_iterable() do
    source = [1, 2, 3]
    g = []
    g_value = 0
    _g = Enum.reduce(source, g, fn x, g_acc ->
      Enum.concat(g_acc, (fn -> [(fn ->
  g_value = 0
  _g = Enum.reduce(source, g, fn y, g_acc -> Enum.concat(g_acc, [x * y]) end)
  []
end).()] end).())
    end)
    g
  end
  def empty_comprehensions() do
    []
  end
  def single_element_nested() do
    [(fn -> g ++ [0] end).()]
  end
  def main() do
    _ = simple_nested()
    _ = constant_range_unrolled()
    _ = nested_with_condition()
    _ = deeply_nested()
    _ = four_level_nesting()
    _ = nested_with_expression()
    _ = nested_with_block()
    _ = mixed_constant_variable()
    _ = nested_in_expression()
    _ = with_meta_and_parens()
    _ = mixed_with_literals()
    _ = comprehension_from_iterable()
    _ = empty_comprehensions()
    _ = single_element_nested()
    nil
  end
end
