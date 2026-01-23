defmodule Main do
  def main() do
    tuple_value = 42
    tuple_tag = "ok"
    _tag = tuple_tag
    _value = tuple_value
    result = ["ok", 42]
    _first_elem = (case result do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "elem") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :elem)
        end)
    end).(0)
    _second_elem = (case result do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "elem") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :elem)
        end)
    end).(1)
    nil
  end
end
