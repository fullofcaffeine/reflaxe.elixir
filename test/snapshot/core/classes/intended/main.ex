defmodule Main do
  def main() do
    p1 = MyApp.Point.new(3, 4)
    p2 = MyApp.Point.new(0, 0)
    Log.trace(p1.distance(p2), %{:file_name => "Main.hx", :line_number => 143, :class_name => "Main", :method_name => "main"})
    shape = shape.new(10, 20, "Rectangle")
    Log.trace(shape.draw(), %{:file_name => "Main.hx", :line_number => 147, :class_name => "Main", :method_name => "main"})
    shape.move(5, 5)
    Log.trace(shape.draw(), %{:file_name => "Main.hx", :line_number => 149, :class_name => "Main", :method_name => "main"})
    circle = circle.new(0, 0, 10)
    Log.trace(circle.draw(), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "main"})
    circle.setVelocity(1, 2)
    circle.update(1.5)
    Log.trace(circle.draw(), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "main"})
    unit_circle = MyApp.Circle.create_unit()
    Log.trace(unit_circle.draw(), %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "main"})
    container = %container{}
    MyApp.StringBuf.add(container, "Hello")
    MyApp.StringBuf.add(container, "World")
    Log.trace(container.get(0), %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "main"})
    Log.trace(container.size(), %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "main"})
    lengths = Enum.map(container, fn s -> length(s) end)
    Log.trace(lengths.get(0), %{:file_name => "Main.hx", :line_number => 171, :class_name => "Main", :method_name => "main"})
  end
end
