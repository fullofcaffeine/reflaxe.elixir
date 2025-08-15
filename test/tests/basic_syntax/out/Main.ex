defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  
  
 * Basic syntax test case
 * Tests fundamental Haxe→Elixir compilation
 
  """

  # Static functions
  @doc "Function greet"
  @spec greet(String.t()) :: String.t()
  def greet(name) do
    "Hello, " <> name <> "!"
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    instance = Main.new(10)
    Log.trace(Main.greet("World"), %{fileName => "Main.hx", lineNumber => 76, className => "Main", methodName => "main"})
    Log.trace(instance.calculate(5, 3), %{fileName => "Main.hx", lineNumber => 77, className => "Main", methodName => "main"})
    Log.trace(instance.checkValue(-5), %{fileName => "Main.hx", lineNumber => 78, className => "Main", methodName => "main"})
    Log.trace(instance.sumRange(1, 10), %{fileName => "Main.hx", lineNumber => 79, className => "Main", methodName => "main"})
    Log.trace(instance.factorial(5), %{fileName => "Main.hx", lineNumber => 80, className => "Main", methodName => "main"})
    Log.trace(instance.dayName(3), %{fileName => "Main.hx", lineNumber => 81, className => "Main", methodName => "main"})
  end

  # Instance functions
  @doc "Function calculate"
  @spec calculate(integer(), integer()) :: integer()
  def calculate(x, y) do
    x + y * __MODULE__.instance_var
  end

  @doc "Function check_value"
  @spec check_value(integer()) :: String.t()
  def check_value(n) do
    if (n < 0), do: "negative", else: if (n == 0), do: "zero", else: "positive"
  end

  @doc "Function sum_range"
  @spec sum_range(integer(), integer()) :: integer()
  def sum_range(start, end_) do
    sum = 0
    _g = start
    _g = end_
    (
      try do
        loop_fn = fn {sum} ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
          # sum updated with + i
          loop_fn.({sum + i})
            catch
              :break -> {sum}
              :continue -> loop_fn.({sum})
            end
          else
            {sum}
          end
        end
        loop_fn.({sum})
      catch
        :break -> {sum}
      end
    )
    sum
  end

  @doc "Function factorial"
  @spec factorial(integer()) :: integer()
  def factorial(n) do
    result = 1
    i = n
    (
      try do
        loop_fn = fn {result, i} ->
          if (i > 1) do
            try do
              # result updated with * i
          # i decremented
          loop_fn.({result * i, i - 1})
            catch
              :break -> {result, i}
              :continue -> loop_fn.({result, i})
            end
          else
            {result, i}
          end
        end
        loop_fn.({result, i})
      catch
        :break -> {result, i}
      end
    )
    result
  end

  @doc "Function day_name"
  @spec day_name(integer()) :: String.t()
  def day_name(day) do
    temp_result = nil
    case (day) do
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
  end

end
