defmodule Shape do
  def draw(struct) do
    "#{(fn -> struct.name end).()} at #{(fn -> Point.to_string(struct.position) end).()}"
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    x = fh.x + dx
    fh = struct.position
    y = fh.y + dy
    y
  end
end
