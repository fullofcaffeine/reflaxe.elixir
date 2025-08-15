defmodule MathHelper do
  use Bitwise
  @moduledoc """
  MathHelper module generated from Haxe
  
  
 * MathHelper - Mathematical operations and calculations for Mix project
 * 
 * This module provides mathematical utilities that demonstrate
 * numerical processing within a Mix project context.
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc "
     * Processes a number through a series of transformations
     * Demonstrates functional composition in a Mix context
     "
  @spec process_number(float()) :: float()
  def process_number(x) do
    step1 = MathHelper.multiplyByFactor(arg0, 2.0)
    step2 = MathHelper.addOffset(step1, 10.0)
    step3 = MathHelper.applyBounds(step2, 0.0, 100.0)
    Math.round(step3)
  end

  @doc "
     * Calculates years until retirement age (65)
     * Useful for user profile calculations
     "
  @spec calculate_years_to_retirement(integer()) :: integer()
  def calculate_years_to_retirement(current_age) do
    retirement_age = 65
    years_left = retirement_age - arg0
    Std.int(Math.max(0, years_left))
  end

  @doc "
     * Calculates discount based on various factors
     * Demonstrates business logic calculations
     "
  @spec calculate_discount(float(), String.t(), integer()) :: term()
  def calculate_discount(base_price, customer_type, quantity) do
    discount = 0.0
    case (arg1) do
      "new" ->
        discount = discount + 0.10
      "premium" ->
        discount = discount + 0.15
      "regular" ->
        discount = discount + 0.05
      _ ->
        discount = discount + 0.0
    end
    if (arg2 >= 10), do: discount = discount + 0.05, else: nil
    if (arg2 >= 50), do: discount = discount + 0.10, else: nil
    if (arg2 >= 100), do: discount = discount + 0.15, else: nil
    discount = Math.min(discount, 0.30)
    discount_amount = arg0 * discount
    final_price = arg0 - discount_amount
    %{basePrice: arg0, discount: discount, discountAmount: discount_amount, finalPrice: final_price, savings: discount_amount}
  end

  @doc "
     * Calculates compound interest
     * Useful for financial calculations in applications
     "
  @spec calculate_compound_interest(float(), float(), integer(), integer()) :: term()
  def calculate_compound_interest(principal, rate, time, compound) do
    if (arg0 <= 0 || arg1 <= 0 || arg2 <= 0 || arg3 <= 0), do: %{error: "Invalid parameters for compound interest calculation"}, else: nil
    rate_decimal = arg1 / 100.0
    amount = arg0 * Math.pow(1 + rate_decimal / arg3, arg3 * arg2)
    interest = amount - arg0
    %{principal: arg0, rate: arg1, time: arg2, compound: arg3, amount: Math.round(amount * 100) / 100, interest: Math.round(interest * 100) / 100}
  end

  @doc "
     * Validates numerical input and provides error information
     "
  @spec validate_number(term()) :: term()
  def validate_number(input) do
    if (arg0 == nil), do: %{valid: false, error: "Input is null"}, else: nil
    number = nil
    try do
      number = Std.parseFloat(Std.string(arg0))
    rescue
      e ->
        %{valid: false, error: "Cannot convert to number"}
    end
    if (Math.isNaN(number)), do: %{valid: false, error: "Input is not a valid number"}, else: nil
    if (!Math.isFinite(number)), do: %{valid: false, error: "Input is not finite"}, else: nil
    %{valid: true, number: number, isInteger: number == Math.floor(number), isPositive: number > 0, isNegative: number < 0, absoluteValue: Math.abs(number)}
  end

  @doc "
     * Performs statistical calculations on an array of numbers
     "
  @spec calculate_stats(Array.t()) :: term()
  def calculate_stats(numbers) do
    if (arg0 == nil || length(arg0) == 0), do: %{error: "Empty or null array provided"}, else: nil
    sum = 0.0
    min = Enum.at(arg0, 0)
    max = Enum.at(arg0, 0)
    _g = 0
    Enum.map(arg0, fn item -> if (num < min), do: num, else: item end)
    mean = sum / length(arg0)
    sorted = arg0
    Enum.sort(sorted, fn a, b -> temp_result = nil
    if (a < b), do: temp_result = -1, else: if (a > b), do: temp_result = 1, else: temp_result = 0
    temp_result end)
    median = nil
    mid_index = Std.int(length(sorted) / 2)
    if (length(sorted) rem 2 == 0), do: median = (Enum.at(sorted, mid_index - 1) + Enum.at(sorted, mid_index)) / 2, else: median = Enum.at(sorted, mid_index)
    %{count: length(arg0), sum: sum, mean: mean, median: median, min: min, max: max, range: max - min}
  end

  @doc "Function multiply_by_factor"
  @spec multiply_by_factor(float(), float()) :: float()
  def multiply_by_factor(value, factor) do
    arg0 * arg1
  end

  @doc "Function add_offset"
  @spec add_offset(float(), float()) :: float()
  def add_offset(value, offset) do
    arg0 + arg1
  end

  @doc "Function apply_bounds"
  @spec apply_bounds(float(), float(), float()) :: float()
  def apply_bounds(value, min, max) do
    if (arg0 < arg1), do: arg1, else: nil
    if (arg0 > arg2), do: arg2, else: nil
    arg0
  end

  @doc "
     * Main function for compilation testing
     "
  @spec main() :: nil
  def main() do
    Log.trace("MathHelper compiled successfully for Mix project!", %{fileName: "src_haxe/utils/MathHelper.hx", lineNumber: 188, className: "utils.MathHelper", methodName: "main"})
  end

end
