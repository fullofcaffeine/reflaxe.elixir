defmodule Main do
  def calculate(struct, x, y) do
    x + y * struct.instance_var
  end
  def check_value(struct, n) do
    cond do
      n < 0 -> "negative"
      n == 0 -> "zero"
      :true -> "positive"
    end
  end
  def sum_range(struct, start, end_param) do
    sum = 0
    _ = Enum.each(0..(end_param - 1), (fn -> fn start ->
  i = start + 1
  sum = sum + i
end end).())
    sum
  end
  def factorial(struct, n) do
    result = 1
    i = n
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i}, (fn -> fn _, {result, i} ->
  if (i > 1) do
    result = result * i
    (i - 1)
    {:cont, {result, i}}
  else
    {:halt, {result, i}}
  end
end end).())
    result
  end
  def day_name(struct, day) do
    (case day do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
      _ -> "Invalid"
    end)
  end
  def greet(name) do
    "Hello, #{(fn -> name end).()}!"
  end
  def main() do
    instance = MyApp.Main.new(10)
    nil
  end
end
