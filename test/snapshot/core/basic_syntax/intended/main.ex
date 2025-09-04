defmodule Main do
  def new(value) do
    %{:instanceVar => value}
  end
  def calculate(struct, x, y) do
    x + y * struct.instanceVar
  end
  def check_value(_struct, n) do
    if (n < 0) do
      "negative"
    else
      if (n == 0), do: "zero", else: "positive"
    end
  end
  def sum_range(_struct, start, end) do
    sum = 0
    g = start
    g1 = end
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, sum, g1, :ok}, fn _, {acc_g, acc_sum, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    acc_sum = acc_sum + i
    {:cont, {acc_g, acc_sum, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_sum, acc_g1, acc_state}}
  end
end)
    sum
  end
  def factorial(_struct, n) do
    result = 1
    i = n
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i, :ok}, fn _, {acc_result, acc_i, acc_state} ->
  if (acc_i > 1) do
    acc_result = acc_result * acc_i
    acc_i = (acc_i - 1)
    {:cont, {acc_result, acc_i, acc_state}}
  else
    {:halt, {acc_result, acc_i, acc_state}}
  end
end)
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
    Log.trace(greet("World"), %{:fileName => "Main.hx", :lineNumber => 76, :className => "Main", :methodName => "main"})
    Log.trace(instance.calculate(5, 3), %{:fileName => "Main.hx", :lineNumber => 77, :className => "Main", :methodName => "main"})
    Log.trace(instance.checkValue(-5), %{:fileName => "Main.hx", :lineNumber => 78, :className => "Main", :methodName => "main"})
    Log.trace(instance.sumRange(1, 10), %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "main"})
    Log.trace(instance.factorial(5), %{:fileName => "Main.hx", :lineNumber => 80, :className => "Main", :methodName => "main"})
    Log.trace(instance.dayName(3), %{:fileName => "Main.hx", :lineNumber => 81, :className => "Main", :methodName => "main"})
  end
end