defmodule Shape do
  def draw(struct) do
    "#{(fn -> struct.name end).()} at #{(fn -> struct.position.toString() end).()}"
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    _ = fh.x + dx
    fh2 = struct.position
    _ = fh2.y + dy
  end
end
