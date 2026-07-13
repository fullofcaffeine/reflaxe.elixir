defmodule Point do
  import Kernel, except: [to_string: 1], warn: false
  def new(x_param, y_param) do
    struct = %{:__reflaxe_class__ => Point, :x => nil, :y => nil}
    struct = %{struct | x: x_param}
    struct = %{struct | y: y_param}
    struct
  end
  def distance(struct, other) do
    dx = Reflaxe.Elixir.HaxeFloat.sub(struct.x, other.x)
    dy = Reflaxe.Elixir.HaxeFloat.sub(struct.y, other.y)
    Reflaxe.Elixir.HaxeFloat.sqrt(Reflaxe.Elixir.HaxeFloat.add(Reflaxe.Elixir.HaxeFloat.mul(dx, dx), Reflaxe.Elixir.HaxeFloat.mul(dy, dy)))
  end
  def to_string(struct) do
    "Point(#{Reflaxe.Elixir.HaxeFloat.to_string(struct.x)}, #{Reflaxe.Elixir.HaxeFloat.to_string(struct.y)})"
  end
end
