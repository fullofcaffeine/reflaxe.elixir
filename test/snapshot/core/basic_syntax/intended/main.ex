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
    _g = start
    _ = end_param
    sum = Enum.reduce(0..(g_value - 1)//1, sum, fn i, sum -> sum + i end)
    sum
    sum
  end
  def factorial(struct, n) do
    result = 1
    i = n
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, 0}, fn _, {result, i} ->
      if (i > 1) do
        result = result * i
        (old_i = i
i = (i - 1)
old_i)
        {:cont, {result, i}}
      else
        {:halt, {result, i}}
      end
    end)
    nil
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
    instance = Main.new(10)
    nil
  end
end
