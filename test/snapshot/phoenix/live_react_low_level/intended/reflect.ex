defmodule Reflect do
  def field(o, field) do
    if Map.has_key?(o, field) do
      Map.get(o, field)
    else
      try do
        Map.get(o, String.to_existing_atom(field))
      rescue
        ArgumentError -> nil
      end
    end
  end
  def set_field(o, field, value) do
    if Map.has_key?(o, field) do
      Map.put(o, field, value)
    else
      try do
        key = String.to_existing_atom(field)
        if Map.has_key?(o, key) do
          Map.put(o, key, value)
        else
          Map.put(o, field, value)
        end
      rescue
        ArgumentError -> Map.put(o, field, value)
      end
    end
  end
  def fields(o) do
    Map.keys(o)
    |> Enum.flat_map(fn k ->
      cond do
        is_atom(k) -> [Atom.to_string(k)]
        is_binary(k) -> [k]
        true -> []
      end
    end)
  end
  def has_field(o, field) do
    if Map.has_key?(o, field) do
      true
    else
      try do
        Map.has_key?(o, String.to_existing_atom(field))
      rescue
        ArgumentError -> false
      end
    end
  end
  def delete_field(o, field) do
    if Map.has_key?(o, field) do
      Map.delete(o, field)
    else
      try do
        key = String.to_existing_atom(field)
        if Map.has_key?(o, key) do
          Map.delete(o, key)
        else
          o
        end
      rescue
        ArgumentError -> o
      end
    end
  end
  def is_object(v) do
    is_map(v)
  end
  def copy(o) do
    o
  end
  def call_method(o, func, args) do
    _ignore_obj = o
    apply(func, args)
  end
  def compare(a, b) do

          cond do
            a == b ->
              0
            is_number(a) and is_number(b) ->
              if a < b, do: -1, else: 1
            is_boolean(a) and is_boolean(b) ->
              if a == false, do: -1, else: 1
            is_binary(a) and is_binary(b) ->
              if a < b, do: -1, else: 1
            true ->
              left = Reflaxe.Elixir.HaxeFloat.to_string(a)
              right = Reflaxe.Elixir.HaxeFloat.to_string(b)
              cond do
                left < right -> -1
                left > right -> 1
                true -> 0
              end
          end

  end
  def is_enum_value(v) do
    is_tuple(v) and tuple_size(v) >= 1 and is_atom(elem(v, 0))
  end
  def is_function(f) do
    Kernel.is_function(f)
  end
  def compare_methods(f1, f2) do
    f1 == f2
  end
  def get_property(o, field) do
    (case {o, field} do
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
  def set_property(o, field, value) do
    (case {o, field, value} do
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
  end
  def make_var_args(f) do
    fn args -> f.(args) end
  end
end
