defmodule Main do
  def main() do
    _ = Point.new(3, 4)
    _ = Point.new(0, 0)
    shape = shape.new(10, 20, "Rectangle")
    _ = shape.move(shape, 5, 5)
    circle = circle.new(0, 0, 10)
    _ = circle.set_velocity(circle, 1, 2)
    _ = circle.update(circle, 1.5)
    unit_circle = circle.create_unit()
    container = %container{}
    _ = container.add(container, "Hello")
    _ = container.add(container, "World")
    lengths = container.map(container, fn s -> String.length(s) end)
    nil
  end
end
