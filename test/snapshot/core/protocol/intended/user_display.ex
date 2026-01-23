defmodule UserDisplay do
  def display(user) do
    "#{user.name} (#{Kernel.to_string(user.age)})"
  end
  def format(user, options) do
    if ((case options do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "verbose") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :verbose)
    end)
end)) do
      "User: #{user.name}, Age: #{Kernel.to_string(user.age)}"
    else
      display(user)
    end
  end
end
