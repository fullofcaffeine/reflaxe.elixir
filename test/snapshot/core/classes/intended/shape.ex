defmodule Shape do
  def draw(struct) do
    "#{struct.name} at #{struct.position.toString()}"
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    x = fh.x + dx
    fh2 = struct.position
    y = fh2.y + dy
  end
end