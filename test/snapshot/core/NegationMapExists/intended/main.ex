defmodule Main do
  def main() do
    error_map = %{}
    field = "test"
    error_map = if (not Map.has_key?(error_map, field)) do
      Map.put(error_map, field, [])
    else
      error_map
    end
    has_field = Map.has_key?(error_map, field)
    error_map = if (not has_field) do
      Map.put(error_map, field, ["value"])
    else
      error_map
    end
    values = Map.get(error_map, field)
    _ = values ++ ["new value"]
    nil
  end
end
