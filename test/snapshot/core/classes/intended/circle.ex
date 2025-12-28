defmodule Circle do
  def new(x, y, radius_param) do
    struct = Shape.new(x, y, "Circle")
    struct = %{struct | radius: radius_param}
    struct = %{struct | velocity: Point.new(0, 0)}
    struct
  end
  def draw(struct) do
    "#{(fn -> Shape.draw(super) end).()} with radius #{(fn -> Kernel.to_string(struct.radius) end).()}"
  end
  def update(struct, dt) do
    Shape.move(struct, struct.velocity.x * dt, struct.velocity.y * dt)
  end
  def set_velocity(_, vx, vy) do
    _x = vx
    y = vy
    y
  end
  def create_unit() do
    Circle.new(0, 0, 1)
  end
end
