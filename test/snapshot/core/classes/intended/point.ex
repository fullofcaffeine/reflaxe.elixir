defmodule Point do
  import Kernel, except: [to_string: 1], warn: false
  def new(x_param, y_param) do
    struct = %{:x => nil, :y => nil}
    struct = %{struct | x: x_param}
    struct = %{struct | y: y_param}
    struct
  end
  def distance(struct, other) do
    dx = (struct.x - other.x)
    dy = (struct.y - other.y)
    :math.sqrt(dx * dx + dy * dy)
  end
  def to_string(struct) do
    "Point(#{(fn -> Kernel.to_string(struct.x) end).()}, #{(fn -> Kernel.to_string(struct.y) end).()})"
  end
end
