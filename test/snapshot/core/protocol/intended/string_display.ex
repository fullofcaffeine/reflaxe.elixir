defmodule StringDisplay do
  def display(value) do
    value
  end
  def format(value, options) do
    if (options.uppercase), do: value.to_upper_case()
    value
  end
end