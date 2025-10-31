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
    Enum.each(0..(end_param - 1), fn item ->
      i = item + 1
      sum = sum + i
    end)
    sum
  end
  def factorial(struct, n) do
    result = 1
    i = n
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i}, fn _, {result, i} ->
      if (i > 1) do
        result = result * i
        (i - 1)
        {:cont, {result, i}}
      else
        {:halt, {result, i}}
      end
    end)
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
    Log.trace(greet("World"), %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.calculate(5, 3), %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.checkValue(-5), %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.sumRange(1, 10), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.factorial(5), %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.dayName(3), %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "main"})
  end
end
