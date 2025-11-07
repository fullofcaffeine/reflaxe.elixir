defmodule Main do
  def main() do
    _ = MyApp.Point.new(3, 4)
    _ = MyApp.Point.new(0, 0)
    _ = Log.trace(p1.distance(p2), %{:file_name => "Main.hx", :line_number => 143, :class_name => "Main", :method_name => "main"})
    shape = shape.new(10, 20, "Rectangle")
    _ = Log.trace(shape.draw(), %{:file_name => "Main.hx", :line_number => 147, :class_name => "Main", :method_name => "main"})
    _ = shape.move(5, 5)
    _ = Log.trace(shape.draw(), %{:file_name => "Main.hx", :line_number => 149, :class_name => "Main", :method_name => "main"})
    circle = circle.new(0, 0, 10)
    _ = Log.trace(circle.draw(), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "main"})
    _ = circle.setVelocity(1, 2)
    _ = circle.update(1.5)
    _ = Log.trace(circle.draw(), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "main"})
    unit_circle = MyApp.Circle.create_unit()
    _ = Log.trace(unit_circle.draw(), %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "main"})
    container = %container{}
    _ = StringBuf.add(container, "Hello")
    _ = StringBuf.add(container, "World")
    _ = Log.trace(container.get(0), %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(container.size(), %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "main"})
    lengths = Enum.map(container, fn s -> length(s) end)
    _ = Log.trace(lengths.get(0), %{:file_name => "Main.hx", :line_number => 171, :class_name => "Main", :method_name => "main"})
  end
end
