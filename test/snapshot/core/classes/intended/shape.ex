defmodule Shape do
  def new(x, y, name_param) do
    struct = %{:__reflaxe_class__ => Shape, :position => nil, :name => nil}
    struct = %{struct | position: Point.new(x, y)}
    struct = %{struct | name: name_param}
    struct
  end
  def draw(struct) do
    "#{struct.name} at #{(fn -> reflaxe_dispatch_receiver = struct.position
apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver]) end).()}"
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    fh = %{fh | x: fh.x + dx}
    fh = struct.position
    fh = %{fh | y: fh.y + dy}
    fh
  end
end
