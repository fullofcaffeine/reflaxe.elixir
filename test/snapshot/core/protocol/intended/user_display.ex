defmodule UserDisplay do
  def display(user) do
    "#{(fn -> user.name end).()} (#{(fn -> Kernel.to_string(user.age) end).()})"
  end
  def format(user, options) do
    if (Map.get(options, :verbose)) do
      "User: #{(fn -> user.name end).()}, Age: #{(fn -> Kernel.to_string(user.age) end).()}"
    end
    _ = display(user)
  end
end
