defmodule Main do
  def main() do
    printer = JsonPrinter.new()
    arr = [1, 2, 3, 4, 5]
    apply(Map.get(printer, :__reflaxe_class__) || Map.get(printer, :__struct__), :write_array, [printer, arr])
    if (apply(Map.get(printer, :__reflaxe_class__) || Map.get(printer, :__struct__), :to_string, [printer]) != "[1, 2, 3, 4, 5]") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "JSON array output must retain all buffer writes"]
    end
    obj = %{name: "test", values: [1, 2, 3]}
    apply(Map.get(printer, :__reflaxe_class__) || Map.get(printer, :__struct__), :write_object, [printer, obj])
  end
end
