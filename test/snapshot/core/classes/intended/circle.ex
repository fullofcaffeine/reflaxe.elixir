defmodule Circle do
  def new(x, y, radius_param) do
    struct = %{:__reflaxe_class__ => Circle, :radius => nil, :velocity => nil}
    struct = Map.merge(struct, Map.delete(Shape.new(x, y, "Circle"), :__struct__))
    struct = %{struct | radius: radius_param}
    struct = %{struct | velocity: Point.new(0, 0)}
    struct
  end
  def draw(struct) do
    "#{Shape.draw(super)} with radius #{Kernel.to_string(struct.radius)}"
  end
  def update(struct, dt) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :move, [struct, struct.velocity.x * dt, struct.velocity.y * dt])
  end
  def set_velocity(_, vx, vy) do
    _x = vx
    y = vy
    y
  end
  def create_unit() do
    Circle.new(0, 0, 1)
  end
  def get_position(struct) do
    Shape.get_position(struct)
  end
  def move(struct, dx, dy) do
    Shape.move(struct, dx, dy)
  end
end
