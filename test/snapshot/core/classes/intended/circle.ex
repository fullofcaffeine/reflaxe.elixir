defmodule Circle do
  def draw(struct) do
    "#{(fn -> Shape.draw(struct) end).()} with radius #{(fn -> Kernel.to_string(struct.radius) end).()}"
  end
  def update(struct, dt) do
    struct.move(struct.velocity.x * dt, struct.velocity.y * dt)
  end
  def set_velocity(struct, vx, vy) do
    _x = vx
    y = vy
    y
  end
  def create_unit() do
    Circle.new(0, 0, 1)
  end
end
