defmodule JoinType do
  def inner() do
    {:Inner}
  end
  def left() do
    {:Left}
  end
  def right() do
    {:Right}
  end
  def full() do
    {:Full}
  end
  def cross() do
    {:Cross}
  end
end