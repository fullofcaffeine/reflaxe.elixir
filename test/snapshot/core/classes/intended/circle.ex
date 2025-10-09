defmodule Circle do
  def draw(struct) do
    "#{Shape.draw(struct)} with radius #{struct.radius}"
  end
  def update(struct, dt) do
    struct.move(struct.velocity.x * dt, struct.velocity.y * dt)
  end
  def set_velocity(struct, vx, vy) do
    x = vx
    y = vy
  end
  def create_unit() do
    Circle.new(0, 0, 1)
  end
end