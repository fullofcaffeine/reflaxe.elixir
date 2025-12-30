defmodule Shape do
  def new(x, y, name_param) do
    struct = %{:position => nil, :name => nil}
    struct = %{struct | position: Point.new(x, y)}
    struct = %{struct | name: name_param}
    struct
  end
  def draw(struct) do
    "#{struct.name} at #{Point.to_string(struct.position)}"
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    _x = fh.x + dx
    fh = struct.position
    y = fh.y + dy
    y
  end
end
