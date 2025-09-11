defmodule PositiveInt_Impl_ do
  def _new(value) do
    if (value <= 0) do
      throw("Value must be positive, got: " <> Kernel.to_string(value))
    end
    this1 = value
    this1
  end
  def parse(value) do
    if (value <= 0), do: {:error, "Value must be positive, got: " <> Kernel.to_string(value)}
    {:ok, value}
  end
  def add(this1, other) do
    this1 + to_int(other)
  end
  def multiply(this1, other) do
    this1 * to_int(other)
  end
  def multiply_by_int(this1, multiplier) do
    if (multiplier <= 0) do
      throw("Multiplier must be positive, got: " <> Kernel.to_string(multiplier))
    end
    this1 * multiplier
  end
  def safe_sub(this1, other) do
    result = (this1 - to_int(other))
    if (result <= 0), do: {:error, "Subtraction result would be non-positive: " <> Kernel.to_string(this1) <> " - " <> Kernel.to_string(to_int(other)) <> " = " <> Kernel.to_string(result)}
    {:ok, result}
  end
  def safe_sub_int(this1, value) do
    result = (this1 - value)
    if (result <= 0), do: {:error, "Subtraction result would be non-positive: " <> Kernel.to_string(this1) <> " - " <> Kernel.to_string(value) <> " = " <> Kernel.to_string(result)}
    {:ok, result}
  end
  def safe_div(this1, divisor) do
    divisor_int = to_int(divisor)
    if (rem(this1, divisor_int) != 0), do: {:error, "Division not exact: " <> Kernel.to_string(this1) <> " / " <> Kernel.to_string(divisor_int) <> " has remainder " <> Kernel.to_string(rem(this1, divisor_int))}
    result = Std.int(this1 / divisor_int)
    if (result <= 0), do: {:error, "Division result would be non-positive: " <> Kernel.to_string(this1) <> " / " <> Kernel.to_string(divisor_int) <> " = " <> Kernel.to_string(result)}
    {:ok, result}
  end
  def div(this1, divisor) do
    Std.int(this1 / to_int(divisor))
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
    Std.string(this1)
  end
  def equals_int(this1, value) do
    this1 == value
  end
  def from_abs(value) do
    parse((if (value < 0) do
  -value
else
  value
end))
  end
end