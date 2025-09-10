defmodule Phoenix.JoinType do
  def inner() do
    {0}
  end
  def left() do
    {1}
  end
  def right() do
    {2}
  end
  def full() do
    {3}
  end
  def cross() do
    {4}
  end
end