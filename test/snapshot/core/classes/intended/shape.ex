defmodule Shape do
  @position nil
  @name nil
  def draw(struct) do
    "" <> struct.name <> " at " <> struct.position.to_string()
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    x = fh.x + dx
    fh = struct.position
    y = fh.y + dy
  end
end