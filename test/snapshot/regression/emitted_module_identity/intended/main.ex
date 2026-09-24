defmodule Main do
  def main() do
    reader = Sample.Reader.new()
    if (apply(Map.get(reader, :__reflaxe_class__) || Map.get(reader, :__struct__), :run, [reader, "value"]) != 7) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Shared module call returned the wrong value."]
    end
    if (apply(Map.get(reader, :__reflaxe_class__) || Map.get(reader, :__struct__), :run, [reader, 42]) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Native value decoder did not reject an integer."]
    end
  end
end
