defmodule Std do
  def string(value) do
    inspect(value)
  end
  def int(value) do
    trunc(value)
  end
end