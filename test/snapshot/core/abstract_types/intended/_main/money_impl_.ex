defmodule Money_Impl_ do
  def _new(cents) do
    this1 = nil
    this1 = cents
    this1
  end
  def add(a, b) do
    _new(to_int(a) + to_int(b))
  end
  def subtract(a, b) do
    _new((to_int(a) - to_int(b)))
  end
  def multiply(a, multiplier) do
    _new(to_int(a) * multiplier)
  end
  def equal(a, b) do
    to_int(a) == to_int(b)
  end
  def to_int(this1) do
    this1
  end
  def to_dollars(this1) do
    this1 / 100
  end
end