defmodule Main do
  def main() do
    printer = JsonPrinter.new()
    arr = [1, 2, 3, 4, 5]
    _ = apply(Map.get(printer, :__reflaxe_class__) || Map.get(printer, :__struct__), :write_array, [printer, arr])
    obj = %{name: "test", values: [1, 2, 3]}
    _ = apply(Map.get(printer, :__reflaxe_class__) || Map.get(printer, :__struct__), :write_object, [printer, obj])
  end
end
