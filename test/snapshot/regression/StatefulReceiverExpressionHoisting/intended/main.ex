defmodule Main do
  defp value_from(input) do
    input + 1
  end
  defp require_true(value, label) do
    if (not value) do
      raise Reflaxe.Elixir.HaxeThrow, [value: label]
    end
  end
  defp require_false(value, label) do
    if (value) do
      raise Reflaxe.Elixir.HaxeThrow, [value: label]
    end
  end
  def main() do
    map = %{}
    seed = 0
    value = value_from(seed)
    map = (case {map, "foo", value} do
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
    bracket_result = value == 1
    map = (case {map, "bar", 2} do
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
    map = (case {map, "baz", 3} do
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
    method_result = true
    had_key = (case {map, "bar"} do
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
    {map, _reflaxe_receiver_value_0} = (case {map, "bar"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> {Map.delete(reflect_obj, reflect_field), true}
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> {reflect_obj, false}
              reflect_atom ->
                (case Map.has_key?(reflect_obj, reflect_atom) do
                  true -> {Map.delete(reflect_obj, reflect_atom), true}
                  false -> {reflect_obj, false}
                end)
            end)
        end)
    end)
    removed_first = had_key
    had_key = (case {map, "bar"} do
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
    {map, _reflaxe_receiver_value_1} = (case {map, "bar"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> {Map.delete(reflect_obj, reflect_field), true}
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> {reflect_obj, false}
              reflect_atom ->
                (case Map.has_key?(reflect_obj, reflect_atom) do
                  true -> {Map.delete(reflect_obj, reflect_atom), true}
                  false -> {reflect_obj, false}
                end)
            end)
        end)
    end)
    removed_second = had_key
    _ = require_true(bracket_result, "bracket result")
    _ = require_true(method_result, "method result")
    _ =
      require_true(((case {map, "foo"} do
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
        end)), "foo exists")
    _ =
      require_false(((case {map, "bar"} do
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
        end)), "bar removed")
    _ =
      require_true(((case {map, "baz"} do
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
        end)), "baz exists")
    _ = require_true(removed_first, "first remove")
    _ = require_false(removed_second, "second remove")
  end
end
