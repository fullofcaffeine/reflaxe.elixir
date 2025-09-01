defmodule Option do
  def none() do
    {:None}
  end
  def some(arg0) do
    {:Some, arg0}
  end
end