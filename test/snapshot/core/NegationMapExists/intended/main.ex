defmodule Main do
  def main() do
    error_map = %{}
    field = "test"
    if (not apply(Map.get(error_map, :__reflaxe_class__) || Map.get(error_map, :__struct__), :exists, [error_map, field])) do
      apply(Map.get(error_map, :__reflaxe_class__) || Map.get(error_map, :__struct__), :set, [error_map, field, []])
    end
    has_field = apply(Map.get(error_map, :__reflaxe_class__) || Map.get(error_map, :__struct__), :exists, [error_map, field])
    if (not has_field) do
      apply(Map.get(error_map, :__reflaxe_class__) || Map.get(error_map, :__struct__), :set, [error_map, field, ["value"]])
    end
    values = apply(Map.get(error_map, :__reflaxe_class__) || Map.get(error_map, :__struct__), :get, [error_map, field])
    _ = values ++ ["new value"]
    nil
  end
end
