defmodule UserHelper do
  def format_name(first_name, last_name) do
    "#{(fn -> first_name end).()} #{(fn -> last_name end).()}"
  end
end
