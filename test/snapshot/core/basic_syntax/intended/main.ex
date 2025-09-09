defmodule Main do
  @instance_var nil
  @constant nil
  @static_var nil
  def calculate(struct, x, y) do
    x + y * struct.instance_var
  end
  def check_value(_struct, n) do
    if (n < 0) do
      "negative"
    else
      if (n == 0), do: "zero", else: "positive"
    end
  end
  def sum_range(_struct, start, end_param) do
    sum = 0
    g = start
    g1 = end_param
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, sum, g, :ok}, fn _, {acc_g1, acc_sum, acc_g, acc_state} -> nil end)
    sum
  end
  def factorial(_struct, n) do
    result = 1
    i = n
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i, :ok}, fn _, {acc_result, acc_i, acc_state} -> nil end)
    result
  end
  def day_name(_struct, day) do
    case (day) do
      1 ->
        "Monday"
      2 ->
        "Tuesday"
      3 ->
        "Wednesday"
      4 ->
        "Thursday"
      5 ->
        "Friday"
      6 ->
        "Saturday"
      7 ->
        "Sunday"
      _ ->
        "Invalid"
    end
  end
  def greet(name) do
    "Hello, " <> name <> "!"
  end
  def main() do
    instance = Main.new(10)
    Log.trace(greet("World"), %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.calculate(5, 3), %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.check_value(-5), %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.sum_range(1, 10), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.factorial(5), %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "main"})
    Log.trace(instance.day_name(3), %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()