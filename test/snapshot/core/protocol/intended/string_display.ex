defmodule StringDisplay do
  def display(value) do
    value
  end
  def format(value, options) do
    if ((case options do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "uppercase") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :uppercase)
    end)
end)) do
      String.upcase(value)
    else
      value
    end
  end
end
