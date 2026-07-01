defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    params = (%{
          "title" => "Ship it",
          "id" => "42",
          "done" => "true",
          "todo" => %{"id" => 99}
        })
    _ = assert_that(PhoenixHx.Params.get_string(params, "title") == "Ship it", "getString failed")
    _ = assert_that(Kernel.is_nil(PhoenixHx.Params.get_string(params, "missing")), "missing getString failed")
    _ = assert_that(PhoenixHx.Params.get_string_default(params, "missing", "fallback") == "fallback", "getStringDefault failed")
    _ = assert_that(PhoenixHx.Params.get_int(params, "id") == 42, "getInt string failed")
    _ = assert_that(PhoenixHx.Params.get_nested_int(params, "todo", "id") == 99, "getNestedInt failed")
    _ = assert_that(PhoenixHx.Params.get_bool(params, "done") == true, "getBool string failed")
    _ = assert_that(PhoenixHx.Params.bool_from_term(PhoenixHx.Params.get(params, "done")) == true, "boolFromTerm string failed")
    _ = assert_that(PhoenixHx.Params.get_int_default(params, "missing", 7) == 7, "getIntDefault failed")
    _ = assert_that(PhoenixHx.Params.string_from_term(PhoenixHx.Params.get(params, "title")) == "Ship it", "stringFromTerm failed")
    _ = assert_that(PhoenixHx.Params.string_from_term_default(nil, "fallback") == "fallback", "stringFromTermDefault failed")
    atom_params = (%{
          title: "Atom title",
          id: 13,
          done: false,
          todo: %{id: "11"}
        })
    _ = assert_that(PhoenixHx.Params.get_string(atom_params, "title") == "Atom title", "atom getString failed")
    _ = assert_that(PhoenixHx.Params.get_int(atom_params, "id") == 13, "atom getInt failed")
    _ = assert_that(PhoenixHx.Params.get_nested_int(atom_params, "todo", "id") == 11, "atom getNestedInt failed")
    _ = assert_that(PhoenixHx.Params.get_bool(atom_params, "done") == false, "atom getBool failed")
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(PhoenixHx.Params.get(atom_params, "params_accessors_missing_atom"), nil), "missing atom fallback failed")
    mixed_params = %{"title" => nil, title: "Atom title"}
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.eq(PhoenixHx.Params.get(mixed_params, "title"), nil), "string-key nil should win over atom fallback")
  end
end
