defmodule QueryOp_Impl_ do
  def _new(value) do
    this1 = nil
    this1 = value
    this1
  end
  def eq(a, b) do
    a == b
  end
  def neq(a, b) do
    a != b
  end
  def lt(a, b) do
    a < b
  end
  def gt(a, b) do
    a > b
  end
  def lte(a, b) do
    a <= b
  end
  def gte(a, b) do
    a >= b
  end
end