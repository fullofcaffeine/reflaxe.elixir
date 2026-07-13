defmodule PositiveInt_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(value) do
    if (value <= 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Value must be positive, got: " <> Reflaxe.Elixir.HaxeFloat.to_string(value)]
    end
    value
  end
  def parse(value) do
    if (value <= 0), do: {:error, "Value must be positive, got: " <> Reflaxe.Elixir.HaxeFloat.to_string(value)}, else: {:ok, value}
  end
  def add(this1, other) do
    this1 + to_int(other)
  end
  def multiply(this1, other) do
    this1 * to_int(other)
  end
  def multiply_by_int(this1, multiplier) do
    if (multiplier <= 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Multiplier must be positive, got: " <> Reflaxe.Elixir.HaxeFloat.to_string(multiplier)]
    end
    this1 * multiplier
  end
  def safe_sub(this1, other) do
    result = (this1 - to_int(other))
    if (result <= 0), do: {:error, "Subtraction result would be non-positive: " <> Reflaxe.Elixir.HaxeFloat.to_string(this1) <> " - " <> Reflaxe.Elixir.HaxeFloat.to_string(to_int(other)) <> " = " <> Reflaxe.Elixir.HaxeFloat.to_string(result)}, else: {:ok, result}
  end
  def safe_sub_int(this1, value) do
    result = (this1 - value)
    if (result <= 0), do: {:error, "Subtraction result would be non-positive: " <> Reflaxe.Elixir.HaxeFloat.to_string(this1) <> " - " <> Reflaxe.Elixir.HaxeFloat.to_string(value) <> " = " <> Reflaxe.Elixir.HaxeFloat.to_string(result)}, else: {:ok, result}
  end
  def safe_div(this1, divisor) do
    divisor_int = to_int(divisor)
    if (rem(this1, divisor_int) != 0) do
      {:error, "Division not exact: " <> Reflaxe.Elixir.HaxeFloat.to_string(this1) <> " / " <> Reflaxe.Elixir.HaxeFloat.to_string(divisor_int) <> " has remainder " <> Reflaxe.Elixir.HaxeFloat.to_string(rem(this1, divisor_int))}
    else
      result = trunc(Reflaxe.Elixir.HaxeFloat.divide(this1, divisor_int))
      if (result <= 0), do: {:error, "Division result would be non-positive: " <> Reflaxe.Elixir.HaxeFloat.to_string(this1) <> " / " <> Reflaxe.Elixir.HaxeFloat.to_string(divisor_int) <> " = " <> Reflaxe.Elixir.HaxeFloat.to_string(result)}, else: {:ok, result}
    end
  end
  def div(this1, divisor) do
    trunc(Reflaxe.Elixir.HaxeFloat.divide(this1, to_int(divisor)))
  end
  def mod(this1, divisor) do
    rem(this1, to_int(divisor))
  end
  def less_than(this1, other) do
    this1 < to_int(other)
  end
  def less_than_or_equal(this1, other) do
    this1 <= to_int(other)
  end
  def greater_than(this1, other) do
    this1 > to_int(other)
  end
  def greater_than_or_equal(this1, other) do
    this1 >= to_int(other)
  end
  def equals(this1, other) do
    this1 == to_int(other)
  end
  def min(this1, other) do
    if (this1 < to_int(other)), do: this1, else: other
  end
  def max(this1, other) do
    if (this1 > to_int(other)), do: this1, else: other
  end
  def to_int(this1) do
    this1
  end
  def to_float(this1) do
    this1
  end
  def to_string(this1) do
    Reflaxe.Elixir.HaxeFloat.to_string(this1)
  end
  def equals_int(this1, value) do
    this1 == value
  end
  def from_abs(value) do
    abs = if (value < 0) do
      -value
    else
      value
    end
    parse(abs)
  end
end
