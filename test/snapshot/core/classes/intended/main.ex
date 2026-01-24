defmodule Main do
  def main() do
    _ = Point.new(3, 4)
    _ = Point.new(0, 0)
    shape = Shape.new(10, 20, "Rectangle")
    _ = apply(Map.get(shape, :__reflaxe_class__) || Map.get(shape, :__struct__), :move, [shape, 5, 5])
    circle = Circle.new(0, 0, 10)
    _ = apply(Map.get(circle, :__reflaxe_class__) || Map.get(circle, :__struct__), :set_velocity, [circle, 1, 2])
    _ = apply(Map.get(circle, :__reflaxe_class__) || Map.get(circle, :__struct__), :update, [circle, 1.5])
    _unit_circle = Circle.create_unit()
    container = Container.new()
    _ = apply(Map.get(container, :__reflaxe_class__) || Map.get(container, :__struct__), :add, [container, "Hello"])
    _ = apply(Map.get(container, :__reflaxe_class__) || Map.get(container, :__struct__), :add, [container, "World"])
    _lengths = apply(Map.get(container, :__reflaxe_class__) || Map.get(container, :__struct__), :map, [container, fn s -> String.length(s) end])
    nil
  end
end
