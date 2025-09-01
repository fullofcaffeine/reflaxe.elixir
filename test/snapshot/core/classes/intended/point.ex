defmodule Point do
  def new(x, y) do
    %{:x => x, :y => y}
  end
  def distance(struct, other) do
    dx = struct.x - other.x
    dy = struct.y - other.y
    Math.sqrt(dx * dx + dy * dy)
  end
  def to_string(struct) do
    "Point(" + struct.x + ", " + struct.y + ")"
  end
end