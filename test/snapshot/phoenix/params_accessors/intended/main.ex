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
    _ = assert_that(PhoenixHx.Params.get_int_default(params, "missing", 7) == 7, "getIntDefault failed")
  end
end
