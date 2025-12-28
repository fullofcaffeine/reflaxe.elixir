defmodule Main do
  def simple_nested() do
    [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g = g ++ [2]
  g
end).(), (fn ->
  g = []
  g = g ++ [3]
  g = g ++ [4]
  g = g ++ [5]
  g
end).(), (fn ->
  g = []
  g = g ++ [6]
  g = g ++ [7]
  g = g ++ [8]
  g
end).()]
  end
  def constant_range_unrolled() do
    [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g
end).(), (fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g
end).()]
  end
  def nested_with_condition() do
    [(fn ->
  g = []
  g ++ [0]
  g ++ [2]
  g
end).(), (fn ->
  g = []
  g ++ [5]
  g ++ [7]
  g
end).(), (fn ->
  g = []
  g ++ [8]
  g ++ [10]
  g
end).(), (fn ->
  g = []
  g ++ [13]
  g ++ [15]
  g
end).()]
  end
  def deeply_nested() do
    [(fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [2]
  g = g ++ [3]
  g
end).()]
  g
end).(), (fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [4]
  g = g ++ [5]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [6]
  g = g ++ [7]
  g
end).()]
  g
end).()]
  end
  def four_level_nesting() do
    [(fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [2]
  g = g ++ [3]
  g
end).()]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [4]
  g = g ++ [5]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [6]
  g = g ++ [7]
  g
end).()]
  g
end).()]
  g
end).(), (fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [8]
  g = g ++ [9]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [10]
  g = g ++ [11]
  g
end).()]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g = []
  g = g ++ [12]
  g = g ++ [13]
  g
end).()]
  g = g ++ [(fn ->
  g = []
  g = g ++ [14]
  g = g ++ [15]
  g
end).()]
  g
end).()]
  g
end).()]
  end
  def nested_with_expression() do
    [(fn ->
  g = []
  g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(0)]
  g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(1)]
  g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(2)]
  g
end).(), (fn ->
  g = []
  g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(0)]
  g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(1)]
  g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(2)]
  g
end).(), (fn ->
  g = []
  g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(0)]
  g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(1)]
  g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(2)]
  g
end).()]
  end
  def nested_with_block() do
    [(fn ->
  g = []
  temp = 0
  g = g ++ [temp]
  temp = 0
  g = g ++ [temp + 1]
  temp = 0
  g = g ++ [temp + 2]
  g
end).(), (fn ->
  g = []
  temp = 0
  g = g ++ [temp + 1]
  temp = 1
  g = g ++ [temp + 2]
  temp = 2
  g = g ++ [temp + 3]
  g
end).(), (fn ->
  g = []
  temp = 0
  g = g ++ [temp + 2]
  temp = 2
  g = g ++ [temp + 3]
  temp = 4
  g = g ++ [temp + 4]
  g
end).()]
  end
  def mixed_constant_variable() do
    n = 3
    g = n
    g = Enum.reduce(0..(g - 1)//1, g, fn i, g_acc ->
      Enum.concat(g_acc, (fn -> [(fn ->
  g_acc = []
  g_acc = Enum.concat(g_acc, [i])
  Enum.concat(g_acc, [i + 1])
end).()] end).())
    end)
    g
  end
  def nested_in_expression() do
    sum = 0
    data = [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g = g ++ [2]
  g
end).(), (fn ->
  g = []
  g = g ++ [1]
  g = g ++ [2]
  g = g ++ [3]
  g
end).(), (fn ->
  g = []
  g = g ++ [2]
  g = g ++ [3]
  g = g ++ [4]
  g
end).()]
    _g = 0
    sum = Enum.reduce(data, sum, fn row, sum_acc ->
      _g = 0
      Enum.reduce(row, sum_acc, fn val, sum_acc -> sum_acc + val end)
    end)
    sum
  end
  def with_meta_and_parens() do
    [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g
end).(), (fn ->
  g = []
  g = g ++ [2]
  g = g ++ [3]
  g
end).()]
  end
  def mixed_with_literals() do
    [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [2]
  g = g ++ [4]
  g
end).(), [10, 20, 30], (fn ->
  g = []
  g = g ++ [100]
  g = g ++ [101]
  g = g ++ [102]
  g
end).()]
  end
  def comprehension_from_iterable() do
    source = [1, 2, 3]
    g = []
    g = Enum.reduce(source, g, fn x, g_acc ->
      Enum.concat(g_acc, (fn -> [(fn ->
  g = Enum.reduce(source, g, fn y, g_acc -> Enum.concat(g_acc, [x * y]) end)
  []
end).()] end).())
    end)
    g
  end
  def empty_comprehensions() do
    []
  end
  def single_element_nested() do
    [(fn ->
  g = []
  g ++ [0]
end).()]
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
