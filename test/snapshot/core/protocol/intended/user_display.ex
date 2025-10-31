defmodule UserDisplay do
  def display(user) do
    "#{(fn -> user.name end).()} (#{(fn -> user.age end).()})"
  end
  def format(user, options) do
    if (Map.get(options, :verbose)) do
      "User: #{(fn -> user.name end).()}, Age: #{(fn -> user.age end).()}"
    end
    display(user)
  end
end
