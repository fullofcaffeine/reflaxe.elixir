defmodule Main do
  def main() do
    msg = %{type: "test", value: 42}
    result1 = parse_message1(msg)
    result2 = parse_message2(msg)
    if (Reflaxe.Elixir.HaxeFloat.enum_to_string(Haxe.Ds.Option, result1) != "Some(found test)" or Reflaxe.Elixir.HaxeFloat.enum_to_string(Haxe.Ds.Option, result2) != "Some(found test)") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Field-switch results must preserve constructor names and payloads"]
    end
    if (Reflaxe.Elixir.HaxeFloat.enum_to_string(Haxe.Ds.Option, parse_message2(nil)) != "None") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "The empty constructor must retain its metadata"]
    end
    success = {:ok, 42}
    failure = {:error, "missing"}
    if (Reflaxe.Elixir.HaxeFloat.enum_to_string(Haxe.Functional.Result, success) != "Ok(42)" or Reflaxe.Elixir.HaxeFloat.enum_to_string(Haxe.Functional.Result, failure) != "Error(missing)") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Library enum metadata must not depend on the package or constructor name"]
    end
  end
  defp parse_message1(msg) do
    (case (case msg do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "type") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :type)
        end)
    end) do
      "other" -> {:some, "found other"}
      "test" -> {:some, "found test"}
      _ -> {:none}
    end)
  end
  defp parse_message2(msg) do
    if (Reflaxe.Elixir.HaxeFloat.eq(msg, nil)) do
      {:none}
    else
      msg_type = (case msg do
        dyn_obj ->
          (case Map.fetch(dyn_obj, "type") do
            {:ok, dyn_value} -> dyn_value
            _ ->
              Map.get(dyn_obj, :type)
          end)
      end)
      (case msg_type do
        "other" -> {:some, "found other"}
        "test" -> {:some, "found test"}
        _ -> {:none}
      end)
    end
  end
end
