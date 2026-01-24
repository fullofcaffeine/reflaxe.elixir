defmodule Main do
  def main() do
    calc = Calculator.new(10)
    _ = apply(Map.get(calc, :__reflaxe_class__) || Map.get(calc, :__struct__), :add, [calc, 5])
    _ = apply(Map.get(calc, :__reflaxe_class__) || Map.get(calc, :__struct__), :multiply, [calc, 3])
    _ = apply(Map.get(calc, :__reflaxe_class__) || Map.get(calc, :__struct__), :concatenate, [calc, "test"])
    nil
  end
end
