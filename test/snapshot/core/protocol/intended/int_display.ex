defmodule IntDisplay do
  def display(value) do
    Reflaxe.Elixir.HaxeFloat.to_string(value)
  end
  def format(value, options) do
    if ((case options do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "hex") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :hex)
    end)
end)) do
      "0x#{StringTools.hex(value, nil)}"
    else
      Reflaxe.Elixir.HaxeFloat.to_string(value)
    end
  end
end
