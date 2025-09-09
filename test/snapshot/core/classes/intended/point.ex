defmodule Point do
  @x nil
  @y nil
  def distance(struct, other) do
    dx = (struct.x - other.x)
    dy = (struct.y - other.y)
    Math.sqrt(dx * dx + dy * dy)
  end
  def to_string(struct) do
    "Point(" <> Kernel.to_string(struct.x) <> ", " <> Kernel.to_string(struct.y) <> ")"
  end
end