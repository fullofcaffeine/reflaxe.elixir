defmodule Main do
  def main() do
    error_map = %{}
    field = "test"
    if (not Map.has_key?(error_map, field)) do
      error_map = Map.put(error_map, field, [])
    end
    has_field = Map.has_key?(error_map, field)
    if (not has_field) do
      error_map = Map.put(error_map, field, ["value"])
    end
    values = Map.get(error_map, field)
    _ = values ++ ["new value"]
    nil
  end
end
