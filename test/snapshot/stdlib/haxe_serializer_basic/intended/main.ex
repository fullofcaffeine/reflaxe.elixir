defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    primitive_wire = Serializer.run(["alpha", 42, true, nil])
    primitive_value = Unserializer.run(primitive_wire)
    assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(primitive_value, 0), "alpha"), "string roundtrip failed")
    assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(primitive_value, 1), 42), "int roundtrip failed")
    assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(primitive_value, 2), true), "bool roundtrip failed")
    assert_that(Reflaxe.Elixir.HaxeFloat.eq(Enum.at(primitive_value, 3), nil), "null roundtrip failed")
    string_map = %{}
    string_map = string_map |> Map.put("one", 1) |> Map.put("two", 2)
    map_wire = Serializer.run(string_map)
    map_value = Unserializer.run(map_wire)
    assert_that(Map.get(map_value, "one") == 1, "string map one failed")
    assert_that(Map.get(map_value, "two") == 2, "string map two failed")
    serializer = Serializer.new()
    apply(Map.get(serializer, :__reflaxe_class__) || Map.get(serializer, :__struct__), :serialize, [serializer, "prefix"])
    apply(Map.get(serializer, :__reflaxe_class__) || Map.get(serializer, :__struct__), :serialize, [serializer, 7])
    instance_wire = apply(Map.get(serializer, :__reflaxe_class__) || Map.get(serializer, :__struct__), :to_string, [serializer])
    assert_that(instance_wire == "y6:prefixi7", "instance serializer buffer failed")
    nil
  end
end
