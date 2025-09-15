defmodule Main do
  def main() do
    p1 = Point.new(3, 4)
    p2 = Point.new(0, 0)
    Log.trace(Point.distance(p1, p2), %{:file_name => "Main.hx", :line_number => 143, :class_name => "Main", :method_name => "main"})

    shape = Shape.new(10, 20, "Rectangle")
    Log.trace(Shape.draw(shape), %{:file_name => "Main.hx", :line_number => 147, :class_name => "Main", :method_name => "main"})
    Shape.move(shape, 5, 5)
    Log.trace(Shape.draw(shape), %{:file_name => "Main.hx", :line_number => 149, :class_name => "Main", :method_name => "main"})

    circle = Circle.new(0, 0, 10)
    Log.trace(Circle.draw(circle), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "main"})
    Circle.set_velocity(circle, 1, 2)
    Circle.update(circle, 1.5)
    Log.trace(Circle.draw(circle), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "main"})

    unit_circle = Circle.create_unit()
    Log.trace(Circle.draw(unit_circle), %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "main"})

    container = Container.new()
    Container.add(container, "Hello")
    Container.add(container, "World")
    Log.trace(Container.get(container, 0), %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "main"})
    Log.trace(Container.size(container), %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "main"})

    lengths = Container.map(container, fn s -> String.length(s) end)
    Log.trace(Container.get(lengths, 0), %{:file_name => "Main.hx", :line_number => 171, :class_name => "Main", :method_name => "main"})
  end
end