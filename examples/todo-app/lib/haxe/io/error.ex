defmodule Haxe.Io.Error do
  def blocked() do
    {:Blocked}
  end
  def overflow() do
    {:Overflow}
  end
  def outside_bounds() do
    {:OutsideBounds}
  end
  def custom(arg0) do
    {:Custom, arg0}
  end
end