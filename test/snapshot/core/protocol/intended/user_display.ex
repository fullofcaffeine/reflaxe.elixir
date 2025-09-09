defmodule UserDisplay do
  def display(user) do
    "" <> user.name <> " (" <> Kernel.to_string(user.age) <> ")"
  end
  def format(user, options) do
    if (options.verbose) do
      "User: " <> user.name <> ", Age: " <> Kernel.to_string(user.age)
    end
    display(user)
  end
end