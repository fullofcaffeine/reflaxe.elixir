defmodule PlainOption do
  def some(arg0) do
    {:Some, arg0}
  end
  def none() do
    {:None}
  end
end