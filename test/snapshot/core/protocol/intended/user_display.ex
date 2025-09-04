defmodule UserDisplay do
  def display(user) do
    "" <> user.name <> " (" <> user.age <> ")"
  end
  def format(user, options) do
    if (options.verbose), do: "User: " <> user.name <> ", Age: " <> user.age
    display(user)
  end
end