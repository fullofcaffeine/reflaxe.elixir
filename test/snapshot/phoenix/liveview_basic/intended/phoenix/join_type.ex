defmodule Phoenix.JoinType do
  def inner() do
    {:inner}
  end
  def left() do
    {:left}
  end
  def right() do
    {:right}
  end
  def full() do
    {:full}
  end
  def cross() do
    {:cross}
  end
end
