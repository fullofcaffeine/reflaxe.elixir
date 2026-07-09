defmodule ReflectTest do
  def test_reflect_has_field(obj, field) do
    (case {obj, field} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def test_reflect_field(obj, field) do
    (case {obj, field} do
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
  end
end
