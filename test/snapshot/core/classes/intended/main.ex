defmodule Main do
  def main() do
    _ = Point.new(3, 4)
    _ = Point.new(0, 0)
    shape = shape.new(10, 20, "Rectangle")
    _ = Shape.move(shape, 5, 5)
    circle = circle.new(0, 0, 10)
    _ = Circle.set_velocity(circle, 1, 2)
    _ = Circle.update(circle, 1.5)
    _unit_circle = Circle.create_unit()
    container = %container{}
    _ = Container.add(container, "Hello")
    _ = Container.add(container, "World")
    _lengths = Container.map(container, fn s -> String.length(s) end)
    nil
  end
end
