defmodule Shape do
  def new(x, y, name_param) do
    struct = %{:__reflaxe_class__ => Shape, :position => nil, :name => nil}
    struct = %{struct | position: Point.new(x, y)}
    struct = %{struct | name: name_param}
    struct
  end
  def draw(struct) do
    "" <> struct.name <> " at " <> (fn ->
      reflaxe_dispatch_receiver_node_0 = struct.position
      apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :to_string, [reflaxe_dispatch_receiver_node_0])
    end).()
  end
  def get_position(struct) do
    struct.position
  end
  def move(struct, dx, dy) do
    fh = struct.position
    _ = %{fh | x: Reflaxe.Elixir.HaxeFloat.add(fh.x, dx)}
    fh = struct.position
    fh = %{fh | y: Reflaxe.Elixir.HaxeFloat.add(fh.y, dy)}
    fh
  end
end
