defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :active => true}
    name = (case {obj, "name"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    _ = assert(name == "John", "Field retrieval should work")
    missing = (case {obj, "missing"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    _ = assert(Kernel.is_nil(missing), "Missing field should return null")
    obj = (case {obj, "age", 31} do
  {reflect_obj, reflect_field, reflect_value} ->
    (case Map.has_key?(reflect_obj, reflect_field) do
      true ->
        Map.put(reflect_obj, reflect_field, reflect_value)
      false ->
        (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
          nil ->
            Map.put(reflect_obj, reflect_field, reflect_value)
          reflect_atom ->
            Map.put(reflect_obj, reflect_atom, reflect_value)
        end)
    end)
end)
    updated = obj
    updated
  end
  defp assert(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: " <> message]
    end
  end
end
