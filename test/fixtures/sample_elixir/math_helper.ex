defmodule MathHelper do
  @moduledoc """
  A simple math utility module for testing extern generation.
  """

  @type number :: integer() | float()
  @type calculation_result :: {:ok, number()} | {:error, String.t()}

  defstruct [:value, :precision]

  @spec add(integer(), integer()) :: integer()
  def add(a, b) do
    a + b
  end

  @spec multiply(number(), number()) :: number()
  def multiply(a, b) do
    a * b
  end

  @spec divide(number(), number()) :: calculation_result()
  def divide(a, b) when b != 0 do
    {:ok, a / b}
  end

  def divide(_a, _b) do
    {:error, "Division by zero"}
  end

  @spec is_positive?(number()) :: boolean()
  def is_positive?(n) do
    n > 0
  end

  @spec square!(number()) :: number()
  def square!(n) do
    n * n
  end

  @spec sum_list(list(number())) :: number()
  def sum_list(numbers) do
    Enum.sum(numbers)
  end

  @spec get_stats(list(number())) :: %{min: number(), max: number(), count: integer()}
  def get_stats(numbers) do
    %{
      min: Enum.min(numbers),
      max: Enum.max(numbers),
      count: length(numbers)
    }
  end

  @spec format_number(number(), integer()) :: String.t()
  def format_number(num, precision \\ 2) do
    :erlang.float_to_binary(num / 1, [{:decimals, precision}])
  end

  def helper_function(x, y) do
    x + y
  end
end