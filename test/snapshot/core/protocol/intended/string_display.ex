defmodule StringDisplay do
  def display(value) do
    value
  end
  def format(value, options) do
    if (options.uppercase) do
      value = String.upcase(value)
    end
    value
  end
end