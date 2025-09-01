defmodule Money_Impl_ do
  def _new(cents) do
    this_1 = nil
    this_1 = cents
    this_1
  end
  def add(a, b) do
    Money_Impl_._new(Money_Impl_.to_int(a) + Money_Impl_.to_int(b))
  end
  def subtract(a, b) do
    Money_Impl_._new(Money_Impl_.to_int(a) - Money_Impl_.to_int(b))
  end
  def multiply(a, multiplier) do
    Money_Impl_._new(Money_Impl_.to_int(a) * multiplier)
  end
  def equal(a, b) do
    Money_Impl_.to_int(a) == Money_Impl_.to_int(b)
  end
  def to_int(this1) do
    this1
  end
  def to_dollars(this1) do
    this1 / 100
  end
end