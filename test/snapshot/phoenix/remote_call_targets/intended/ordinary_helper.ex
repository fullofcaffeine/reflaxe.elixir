defmodule OrdinaryHelper do
  def assign(value, scale, offset) do
    value * scale + offset
  end
end
