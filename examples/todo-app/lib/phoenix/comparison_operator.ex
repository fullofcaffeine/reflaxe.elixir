defmodule Phoenix.ComparisonOperator do
  def equal() do
    {0}
  end
  def not_equal() do
    {1}
  end
  def greater_than() do
    {2}
  end
  def greater_than_or_equal() do
    {3}
  end
  def less_than() do
    {4}
  end
  def less_than_or_equal() do
    {5}
  end
  def in_fn(arg0) do
    {6, arg0}
  end
  def like(arg0) do
    {7, arg0}
  end
  def is_null() do
    {8}
  end
  def is_not_null() do
    {9}
  end
end