defmodule Main do
  def main() do
    _ = MyApp.Point.new(3, 4)
    _ = MyApp.Point.new(0, 0)
    shape = shape.new(10, 20, "Rectangle")
    _ = shape.move(5, 5)
    circle = circle.new(0, 0, 10)
    _ = circle.setVelocity(1, 2)
    _ = circle.update(1.5)
    unit_circle = circle.create_unit()
    container = %container{}
    _ = StringBuf.add(container, "Hello")
    _ = StringBuf.add(container, "World")
    lengths = Enum.map(container, fn s -> length(s) end)
    nil
  end
end
