defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :is_active => true, :nested_data => %{:street_address => "123 Main St"}}
    _has_name = (case {obj, "name"} do
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
    _has_age = (case {obj, "age"} do
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
    _has_email = (case {obj, "email"} do
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
    _has_is_active = (case {obj, "isActive"} do
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
    _has_nested_data = (case {obj, "nestedData"} do
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
    field_name = "name"
    _has_field_dynamic = (case {obj, field_name} do
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
    _has_street_address = (case {obj.nested_data, "streetAddress"} do
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
    _name_value = (case {obj, "name"} do
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
    _fields = Reflect.fields(obj)
    {reflect_deleted_obj, obj} = (case {obj, "age"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> {true, Map.delete(reflect_obj, reflect_field)}
          false ->
            (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
              nil -> {false, reflect_obj}
              reflect_atom -> {Map.has_key?(reflect_obj, reflect_atom), Map.delete(reflect_obj, reflect_atom)}
            end)
        end)
    end)
    obj_without_age = reflect_deleted_obj
    _still_has_age = (case {obj_without_age, "age"} do
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
    obj_with_email = (case {obj, "email", "john@example.com"} do
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
    _now_has_email = (case {obj_with_email, "email"} do
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
    nil
  end
end
