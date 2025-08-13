defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Basic syntax test case
 * Tests fundamental Haxe→Elixir compilation
 
  """

  # Static functions
  @doc "Function greet"
  @spec greet(String.t()) :: String.t()
  def greet(arg0) do
    "Hello, " + name + "!"
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
  instance = Main.new(10)
  Log.trace(Main.greet("World"), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "main"})
  Log.trace(instance.calculate(5, 3), %{fileName: "Main.hx", lineNumber: 77, className: "Main", methodName: "main"})
  Log.trace(instance.checkValue(-5), %{fileName: "Main.hx", lineNumber: 78, className: "Main", methodName: "main"})
  Log.trace(instance.sumRange(1, 10), %{fileName: "Main.hx", lineNumber: 79, className: "Main", methodName: "main"})
  Log.trace(instance.factorial(5), %{fileName: "Main.hx", lineNumber: 80, className: "Main", methodName: "main"})
  Log.trace(instance.dayName(3), %{fileName: "Main.hx", lineNumber: 81, className: "Main", methodName: "main"})
)
  end

  # Instance functions
  @doc "Function calculate"
  @spec calculate(integer(), integer()) :: integer()
  def calculate(arg0, arg1) do
    x + y * self().instance_var
  end

  @doc "Function check_value"
  @spec check_value(integer()) :: String.t()
  def check_value(arg0) do
    if (n < 0), do: "negative", else: if (n == 0), do: "zero", else: "positive"
  end

  @doc "Function sum_range"
  @spec sum_range(integer(), integer()) :: integer()
  def sum_range(arg0, arg1) do
    (
  sum = 0
  (
  _g = start
  _g1 = end
  while (_g < _g1) do
  (
  i = _g + 1
  sum += i
)
end
)
  sum
)
  end

  @doc "Function factorial"
  @spec factorial(integer()) :: integer()
  def factorial(arg0) do
    (
  result = 1
  i = n
  while (i > 1) do
  (
  result *= i
  i - 1
)
end
  result
)
  end

  @doc "Function day_name"
  @spec day_name(integer()) :: String.t()
  def day_name(arg0) do
    (
  temp_result = nil
  case ((day)) do
  1 ->
    temp_result = "Monday"
  2 ->
    temp_result = "Tuesday"
  3 ->
    temp_result = "Wednesday"
  4 ->
    temp_result = "Thursday"
  5 ->
    temp_result = "Friday"
  6 ->
    temp_result = "Saturday"
  7 ->
    temp_result = "Sunday"
  _ ->
    temp_result = "Invalid"
end
  temp_result
)
  end

end
