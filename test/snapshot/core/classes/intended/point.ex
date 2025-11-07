defmodule Point do
  def distance(struct, other) do
    dx = (struct.x - other.x)
    dy = (struct.y - other.y)
    :math.sqrt(dx * dx + dy * dy)
  end
  def to_string(struct) do
    "Point(#{(fn -> struct.x end).()}, #{(fn -> struct.y end).()})"
  end
end
