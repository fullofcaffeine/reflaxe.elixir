defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    obj = Jason.decode!("{\"name\":\"Ada\",\"count\":3,\"items\":[1,true,null],\"escaped\":\"line\\nnext\"}")
    _ =
      assert_that((fn -> Reflaxe.Elixir.HaxeFloat.eq(((case {obj, "name"} do
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
        end)), "Ada") end).(), "json object string field failed")
    _ =
      assert_that((fn -> Reflaxe.Elixir.HaxeFloat.eq(((case {obj, "count"} do
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
        end)), 3) end).(), "json object int field failed")
    _ =
      assert_that((fn -> Reflaxe.Elixir.HaxeFloat.eq(((case {obj, "escaped"} do
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
        end)), "line\nnext") end).(), "json escaped string failed")
    items = (case {obj, "items"} do
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
    _ = assert_that(length(items) == 3, "json array length failed")
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(items, 0), 1), "json array int failed")
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(items, 1), true), "json array bool failed")
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(items, 2), nil), "json array null failed")
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(Jason.decode!("\"ok\""), "ok"), "top-level json string failed")
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(Jason.decode!("null"), nil), "top-level json null failed")
    try do
      _ = Jason.decode!("{\"unterminated\":")
      _ = assert_that(false, "invalid json should raise")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} ->
            assert_that(Reflaxe.Elixir.HaxeFloat.neq(error, nil), "invalid json should expose an error")
        end)
    end
  end
end
