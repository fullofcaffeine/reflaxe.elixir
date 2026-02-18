defmodule Assigns_Impl_ do
  def from_dynamic(value) do
    value
  end
  def from_object(obj) do
    obj
  end
  def to_dynamic(this1) do
    this1
  end
  def get(this1, key) do
    (case {this1, key} do
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
  def set(this1, key, value) do
    _ = (case {this1, key, value} do
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
    value
  end
  def get_field(this1, field) do
    (case {this1, field} do
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
  def set_field(this1, field, value) do
    _ = (case {this1, field, value} do
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
    value
  end
  def has_field(this1, field) do
    (case {this1, field} do
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
  def get_fields(this1) do
    Reflect.fields(this1)
  end
  def merge(this1, other) do
    result = %{}
    _g = 0
    g_value = Reflect.fields(this1)
    _ = Enum.each(g_value, fn field ->
  result = (case {result, field, (case {this1, field} do
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
end)} do
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
end)
    _g = 0
    g_value = Reflect.fields(to_dynamic(other))
    _ = Enum.each(g_value, fn field ->
  result = (case {result, field, (case {to_dynamic(other), field} do
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
end)} do
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
end)
    _ = from_dynamic(result)
  end
  def with_field(this1, field, value) do
    result = %{}
    _g = 0
    g_value = Reflect.fields(this1)
    _ = Enum.each(g_value, fn existing_field ->
  result = (case {result, existing_field, (case {this1, existing_field} do
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
end)} do
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
end)
    result = (case {result, field, value} do
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
    _ = from_dynamic(result)
  end
end
