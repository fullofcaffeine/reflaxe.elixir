defmodule Main do
  @constant 42
  @static_var "hello"

  defstruct instance_var: nil

  def new(value) do
    %Main{instance_var: value}
  end

  def greet(name) do
    "Hello, #{name}!"
  end

  def calculate(%Main{instance_var: instance_var}, x, y) do
    x + y * instance_var
  end

  def check_value(_main, n) do
    cond do
      n < 0 -> "negative"
      n == 0 -> "zero"
      true -> "positive"
    end
  end

  def sum_range(_main, start, end_param) do
    Enum.reduce(start..(end_param - 1), 0, fn i, sum -> sum + i end)
  end

  def factorial(_main, n) do
    Enum.reduce(1..n, 1, fn i, result -> result * i end)
  end

  def day_name(_main, day) do
    case day do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
      _ -> "Invalid"
    end
  end

  def process_list(_main, items) do
    for item <- items, item > 10, do: item * 2
  end

  def main() do
    main_instance = Main.new(5)

    IO.puts(Main.greet("World"))
    IO.inspect(Main.calculate(main_instance, 10, 3))
    IO.puts(Main.check_value(main_instance, -5))
    IO.puts(Main.check_value(main_instance, 0))
    IO.puts(Main.check_value(main_instance, 10))
    IO.inspect(Main.sum_range(main_instance, 1, 10))
    IO.inspect(Main.factorial(main_instance, 5))
    IO.puts(Main.day_name(main_instance, 3))
    IO.inspect(Main.process_list(main_instance, [5, 12, 8, 15, 3]))

    IO.inspect(@constant)
    IO.puts(@static_var)
  end
end