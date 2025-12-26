defmodule Main do
  def simple_nested() do
    [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  _ = g ++ [2]
  []
end).(), (fn ->
  _ = g ++ [3]
  _ = g ++ [4]
  _ = g ++ [5]
  []
end).(), (fn ->
  _ = g ++ [6]
  _ = g ++ [7]
  _ = g ++ [8]
  []
end).()]
  end
  def constant_range_unrolled() do
    [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).(), (fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
  end
  def nested_with_condition() do
    [(fn ->
  g ++ [0]
  nil
  g ++ [2]
  nil
  []
end).(), (fn ->
  nil
  g ++ [5]
  nil
  g ++ [7]
  []
end).(), (fn ->
  g ++ [8]
  nil
  g ++ [10]
  nil
  []
end).(), (fn ->
  nil
  g ++ [13]
  nil
  g ++ [15]
  []
end).()]
  end
  def deeply_nested() do
    [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [2]
  _ = g ++ [3]
  []
end).()]
  []
end).(), (fn ->
  _ = g ++ [(fn ->
  _ = g ++ [4]
  _ = g ++ [5]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [6]
  _ = g ++ [7]
  []
end).()]
  []
end).()]
  end
  def four_level_nesting() do
    [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [2]
  _ = g ++ [3]
  []
end).()]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [4]
  _ = g ++ [5]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [6]
  _ = g ++ [7]
  []
end).()]
  []
end).()]
  []
end).(), (fn ->
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [8]
  _ = g ++ [9]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [10]
  _ = g ++ [11]
  []
end).()]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [12]
  _ = g ++ [13]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [14]
  _ = g ++ [15]
  []
end).()]
  []
end).()]
  []
end).()]
  end
  def nested_with_expression() do
    [(fn ->
  _ = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(0)]
  _ = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(1)]
  _ = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(2)]
  []
end).(), (fn ->
  _ = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(0)]
  _ = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(1)]
  _ = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(2)]
  []
end).(), (fn ->
  _ = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(0)]
  _ = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(1)]
  _ = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(2)]
  []
end).()]
  end
  def nested_with_block() do
    [(fn ->
  temp = 0
  _ = g ++ [temp]
  temp = 0
  _ = g ++ [temp + 1]
  temp = 0
  _ = g ++ [temp + 2]
  []
end).(), (fn ->
  temp = 0
  _ = g ++ [temp + 1]
  temp = 1
  _ = g ++ [temp + 2]
  temp = 2
  _ = g ++ [temp + 3]
  []
end).(), (fn ->
  temp = 0
  _ = g ++ [temp + 2]
  temp = 2
  _ = g ++ [temp + 3]
  temp = 4
  _ = g ++ [temp + 4]
  []
end).()]
  end
  def mixed_constant_variable() do
    n = 3
    g = []
    g = n
    Enum.reduce(0..(g - 1)//1, g, (fn -> fn i, g ->
      Enum.concat(g, (fn -> [(fn ->
  _ = Enum.concat(g, [i])
  _ = Enum.concat(g, [i + 1])
  []
end).()] end).())
    end end).())
    g
  end
  def nested_in_expression() do
    sum = 0
    _ = [(fn ->
  _ = [0]
  _ = [1]
  _ = [2]
  []
end).()]
    _ = [(fn ->
  _ = [1]
  _ = [2]
  _ = [3]
  []
end).()]
    _ = [(fn ->
  _ = [2]
  _ = [3]
  _ = [4]
  []
end).()]
    data = []
    _g = 0
    _ = Enum.each(data, (fn -> fn row ->
  _g = 0
  _ = row.each(row, fn val -> sum = sum + val end)
end end).())
    sum
  end
  def with_meta_and_parens() do
    [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).(), (fn ->
  _ = g ++ [2]
  _ = g ++ [3]
  []
end).()]
  end
  def mixed_with_literals() do
    [(fn ->
  _ = g ++ [0]
  _ = g ++ [2]
  _ = g ++ [4]
  []
end).(), [10, 20, 30], (fn ->
  _ = g ++ [100]
  _ = g ++ [101]
  _ = g ++ [102]
  []
end).()]
  end
  def comprehension_from_iterable() do
    source = [1, 2, 3]
    g = 0
    _ = Enum.each(source, (fn -> fn x ->
  x ++ [(fn ->
  g = []
  g = 0
  _ = Enum.each(source, fn y -> x ++ [x * y] end)
  x
end).()]
end end).())
    []
  end
  def empty_comprehensions() do
    []
  end
  def single_element_nested() do
    [(fn ->
  _ = g ++ [0]
  []
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
