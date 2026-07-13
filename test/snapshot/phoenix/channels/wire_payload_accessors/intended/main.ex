defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    payload = %{}
    payload = payload |> Map.put("s", "hello") |> Map.put("i", 123) |> Map.put("b", true) |> Map.put("f", 1.25)
    assert_that(Phoenix.Channels.WirePayload.get_string(payload, "s") == "hello", "getString failed")
    assert_that(Phoenix.Channels.WirePayload.get_int(payload, "i") == 123, "getInt failed")
    assert_that(Phoenix.Channels.WirePayload.get_bool(payload, "b") == true, "getBool failed")
    assert_that(Reflaxe.Elixir.HaxeFloat.eq(Phoenix.Channels.WirePayload.get_float(payload, "f"), 1.25), "getFloat failed")
    payload = Map.put(payload, "i_str", "456")
    assert_that(Phoenix.Channels.WirePayload.get_int(payload, "i_str") == 456, "getInt (string) failed")
    payload = Map.put(payload, "i_float", 789)
    assert_that(Phoenix.Channels.WirePayload.get_int(payload, "i_float") == 789, "getInt (integral float) failed")
    nested = %{}
    nested = Map.put(nested, "n", "x")
    payload = Map.put(payload, "nested", nested)
    got_nested = Phoenix.Channels.WirePayload.get_payload(payload, "nested")
    assert_that(Reflaxe.Elixir.HaxeFloat.neq(got_nested, nil), "getPayload failed")
    assert_that(Phoenix.Channels.WirePayload.get_string(got_nested, "n") == "x", "nested getString failed")
    sa_terms = [:ok, "hi"]
    payload = Map.put(payload, "sa", sa_terms)
    sa = Phoenix.Channels.WirePayload.get_string_array(payload, "sa")
    assert_that(not Kernel.is_nil(sa), "getStringArray failed")
    assert_that(Enum.at(sa, 0) == "ok" and Enum.at(sa, 1) == "hi", "getStringArray values failed")
    value = [1, "2", 3.0]
    payload = Map.put(payload, "ia", value)
    ia = Phoenix.Channels.WirePayload.get_int_array(payload, "ia")
    assert_that(not Kernel.is_nil(ia), "getIntArray failed")
    assert_that(Enum.at(ia, 0) == 1 and Enum.at(ia, 1) == 2 and Enum.at(ia, 2) == 3, "getIntArray values failed")
  end
end
