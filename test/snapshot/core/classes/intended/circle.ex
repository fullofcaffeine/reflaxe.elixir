defmodule Circle do
  @radius nil
  @velocity nil
  def draw(struct) do
    "" <> nil.draw() <> " with radius " <> Kernel.to_string(struct.radius)
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