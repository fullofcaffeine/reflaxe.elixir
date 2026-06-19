defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    _g = 0
    g_value = Reflect.fields(obj)
    _ = Enum.each(g_value, fn _ -> nil end)
    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = (case {data, "errors"} do
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
    if (Reflaxe.Elixir.HaxeFloat.neq(changeset_errors, nil)) do
      _g = 0
      g_value = Reflect.fields(changeset_errors)
      _ = Enum.each(g_value, fn field ->
  field_errors = (case {changeset_errors, field} do
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
  if (Std.is(field_errors, Array)) do
    _g = 0
    g_value = field_errors
    _ = Enum.each(g_value, fn _ -> nil end)
  end
end)
    end
  end
end
