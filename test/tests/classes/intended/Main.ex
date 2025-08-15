defmodule Drawable do
  @moduledoc """
  Drawable behavior generated from Haxe interface
  
  
 * Classes test case
 * Tests class compilation, inheritance, and interfaces
 
  """

  @callback draw() :: String.t()
  @callback get_position() :: Point.t()
end


defmodule Updatable do
  @moduledoc """
  Updatable behavior generated from Haxe interface
  """

  @callback update(float()) :: nil
end


defmodule Point do
  use Bitwise
  @moduledoc """
  Point module generated from Haxe
  """

  # Instance functions
  @doc "Function distance"
  @spec distance(Point.t()) :: float()
  def distance(other) do
    dx = __MODULE__.x - other.x
    dy = __MODULE__.y - other.y
    Math.sqrt(dx * dx + dy * dy)
  end

  @doc "Function to_string"
  @spec to_string() :: String.t()
  def to_string() do
    "Point(" <> Float.to_string(__MODULE__.x) <> ", " <> Float.to_string(__MODULE__.y) <> ")"
  end

end


defmodule Shape do
  use Bitwise
  @behaviour Drawable

  @moduledoc """
  Shape module generated from Haxe
  """

  # Instance functions
  @doc "Function draw"
  @spec draw() :: String.t()
  def draw() do
    "" <> __MODULE__.name <> " at " <> __MODULE__.position.toString()
  end

  @doc "Function get_position"
  @spec get_position() :: Point.t()
  def get_position() do
    __MODULE__.position
  end

  @doc "Function move"
  @spec move(float(), float()) :: nil
  def move(dx, dy) do
    fh = __MODULE__.position
    fh.x = fh.x + dx
    fh = __MODULE__.position
    fh.y = fh.y + dy
  end

end


defmodule Circle do
  use Bitwise
  @behaviour Updatable

  @moduledoc """
  Circle module generated from Haxe
  """

  # Static functions
  @doc "Function create_unit"
  @spec create_unit() :: Circle.t()
  def create_unit() do
    Circle.new(0, 0, 1)
  end

  # Instance functions
  @doc "Function draw"
  @spec draw() :: String.t()
  def draw() do
    "" <> __MODULE__.draw() <> " with radius " <> Float.to_string(__MODULE__.radius)
  end

  @doc "Function update"
  @spec update(float()) :: nil
  def update(dt) do
    __MODULE__.move(__MODULE__.velocity.x * dt, __MODULE__.velocity.y * dt)
  end

  @doc "Function set_velocity"
  @spec set_velocity(float(), float()) :: nil
  def set_velocity(vx, vy) do
    __MODULE__.velocity.x = vx
    __MODULE__.velocity.y = vy
  end

end


defmodule Vehicle do
  use Bitwise
  @moduledoc """
  Vehicle module generated from Haxe
  """

  # Instance functions
  @doc "Function accelerate"
  @spec accelerate() :: nil
  def accelerate() do
    throw("Abstract method")
  end

end


defmodule Container do
  use Bitwise
  @moduledoc """
  Container module generated from Haxe
  """

  # Instance functions
  @doc "Function add"
  @spec add(T.t()) :: nil
  def add(item) do
    __MODULE__.items ++ [item]
  end

  @doc "Function get"
  @spec get(integer()) :: T.t()
  def get(index) do
    Enum.at(__MODULE__.items, index)
  end

  @doc "Function size"
  @spec size() :: integer()
  def size() do
    length(__MODULE__.items)
  end

  @doc "Function map"
  @spec map(Function.t()) :: Container.t()
  def map(fn_) do
    result = Container.new()
    _g = 0
    _g = __MODULE__.items
    Enum.map(_g, fn item -> item = Enum.at(_g, _g)
    _g = _g + 1
    result.add(fn_.(item)) end)
    result
  end

end


defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    p1 = Point.new(3, 4)
    p2 = Point.new(0, 0)
    Log.trace(p1.distance(p2), %{fileName => "Main.hx", lineNumber => 143, className => "Main", methodName => "main"})
    shape = Shape.new(10, 20, "Rectangle")
    Log.trace(shape.draw(), %{fileName => "Main.hx", lineNumber => 147, className => "Main", methodName => "main"})
    shape.move(5, 5)
    Log.trace(shape.draw(), %{fileName => "Main.hx", lineNumber => 149, className => "Main", methodName => "main"})
    circle = Circle.new(0, 0, 10)
    Log.trace(circle.draw(), %{fileName => "Main.hx", lineNumber => 153, className => "Main", methodName => "main"})
    circle.setVelocity(1, 2)
    circle.update(1.5)
    Log.trace(circle.draw(), %{fileName => "Main.hx", lineNumber => 156, className => "Main", methodName => "main"})
    unit_circle = Circle.createUnit()
    Log.trace(unit_circle.draw(), %{fileName => "Main.hx", lineNumber => 160, className => "Main", methodName => "main"})
    container = Container.new()
    container.add("Hello")
    container.add("World")
    Log.trace(container.get(0), %{fileName => "Main.hx", lineNumber => 166, className => "Main", methodName => "main"})
    Log.trace(container.size(), %{fileName => "Main.hx", lineNumber => 167, className => "Main", methodName => "main"})
    lengths = Enum.map(container, fn s -> String.length(s) end)
    Log.trace(lengths.get(0), %{fileName => "Main.hx", lineNumber => 171, className => "Main", methodName => "main"})
  end

end
