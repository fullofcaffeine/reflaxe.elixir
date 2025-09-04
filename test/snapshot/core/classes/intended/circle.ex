defmodule Circle do
  def new(x, y, radius) do
    %{:radius => radius, :velocity => Point.new(0, 0)}
  end
  def draw(struct) do
    "" <> nil.draw() <> " with radius " <> struct.radius
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