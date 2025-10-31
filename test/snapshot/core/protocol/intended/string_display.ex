defmodule StringDisplay do
  def display(value) do
    value
  end
  def format(value, options) do
    if (Map.get(options, :uppercase)) do
      String.upcase(value)
    end
    value
  end
end
