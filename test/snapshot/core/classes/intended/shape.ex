defmodule Shape do
  def new(x, y, name) do
    %{:position => Point.new(x, y), :name => name}
  end
  def draw(struct) do
    "" <> struct.name <> " at " <> struct.position.toString()
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