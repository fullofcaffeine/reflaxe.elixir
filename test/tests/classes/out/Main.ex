defmodule Drawable do
  @moduledoc """
  Drawable module generated from Haxe
  
  
 * Classes test case
 * Tests class compilation, inheritance, and interfaces
 
  """

  # Instance functions
  @doc "Function draw"
  @spec draw() :: TInst(String,[]).t()
  def draw() do
    # TODO: Implement function body
    nil
  end

  @doc "Function get_position"
  @spec get_position() :: TInst(Point,[]).t()
  def get_position() do
    # TODO: Implement function body
    nil
  end

end


defmodule Updatable do
  @moduledoc """
  Updatable module generated from Haxe
  """

  # Instance functions
  @doc "Function update"
  @spec update(TAbstract(Float,[]).t()) :: TAbstract(Void,[]).t()
  def update(arg0) do
    # TODO: Implement function body
    nil
  end

end


defmodule Point do
  @moduledoc """
  Point module generated from Haxe
  """

  # Instance functions
  @doc "Function distance"
  @spec distance(TInst(Point,[]).t()) :: TAbstract(Float,[]).t()
  def distance(arg0) do
    (
  dx = self().x - other.x
  dy = self().y - other.y
  Math.sqrt(dx * dx + dy * dy)
)
  end

  @doc "Function to_string"
  @spec to_string() :: TInst(String,[]).t()
  def to_string() do
    "Point(" + self().x + ", " + self().y + ")"
  end

end


defmodule Shape do
  @moduledoc """
  Shape module generated from Haxe
  """

  # Instance functions
  @doc "Function draw"
  @spec draw() :: TInst(String,[]).t()
  def draw() do
    "" + self().name + " at " + self().position.toString()
  end

  @doc "Function get_position"
  @spec get_position() :: TInst(Point,[]).t()
  def get_position() do
    self().position
  end

  @doc "Function move"
  @spec move(TAbstract(Float,[]).t(), TAbstract(Float,[]).t()) :: TAbstract(Void,[]).t()
  def move(arg0, arg1) do
    (
  fh = self().position
  fh.x += dx
  fh2 = self().position
  fh2.y += dy
)
  end

end


defmodule Circle do
  @moduledoc """
  Circle module generated from Haxe
  """

  # Static functions
  @doc "Function create_unit"
  @spec create_unit() :: TInst(Circle,[]).t()
  def create_unit() do
    Circle.new(0, 0, 1)
  end

  # Instance functions
  @doc "Function draw"
  @spec draw() :: TInst(String,[]).t()
  def draw() do
    "" + super().draw() + " with radius " + self().radius
  end

  @doc "Function update"
  @spec update(TAbstract(Float,[]).t()) :: TAbstract(Void,[]).t()
  def update(arg0) do
    self().move(self().velocity.x * dt, self().velocity.y * dt)
  end

  @doc "Function set_velocity"
  @spec set_velocity(TAbstract(Float,[]).t(), TAbstract(Float,[]).t()) :: TAbstract(Void,[]).t()
  def set_velocity(arg0, arg1) do
    (
  self().velocity.x = vx
  self().velocity.y = vy
)
  end

end


defmodule Vehicle do
  @moduledoc """
  Vehicle module generated from Haxe
  """

  # Instance functions
  @doc "Function accelerate"
  @spec accelerate() :: TAbstract(Void,[]).t()
  def accelerate() do
    throw("Abstract method")
  end

end


defmodule Container do
  @moduledoc """
  Container module generated from Haxe
  """

  # Instance functions
  @doc "Function add"
  @spec add(TInst(Container.T,[]).t()) :: TAbstract(Void,[]).t()
  def add(arg0) do
    self().items.push(item)
  end

  @doc "Function get"
  @spec get(TAbstract(Int,[]).t()) :: TInst(Container.T,[]).t()
  def get(arg0) do
    Enum.at(self().items, index)
  end

  @doc "Function size"
  @spec size() :: TAbstract(Int,[]).t()
  def size() do
    self().items.length
  end

  @doc "Function map"
  @spec map(TFun([{name: , t: TInst(Container.T,[]), opt: false}],TInst(map.U,[])).t()) :: TInst(Container,[TInst(map.U,[])]).t()
  def map(arg0) do
    (
  result = Container.new()
  (
  _g = 0
  _g1 = self().items
  while (_g < _g1.length) do
  (
  item = Enum.at(_g1, _g)
  _g + 1
  result.add(fn(item))
)
end
)
  result
)
  end

end


defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  p1 = Point.new(3, 4)
  p2 = Point.new(0, 0)
  Log.trace(p1.distance(p2), %{fileName: "Main.hx", lineNumber: 143, className: "Main", methodName: "main"})
  shape = Shape.new(10, 20, "Rectangle")
  Log.trace(shape.draw(), %{fileName: "Main.hx", lineNumber: 147, className: "Main", methodName: "main"})
  shape.move(5, 5)
  Log.trace(shape.draw(), %{fileName: "Main.hx", lineNumber: 149, className: "Main", methodName: "main"})
  circle = Circle.new(0, 0, 10)
  Log.trace(circle.draw(), %{fileName: "Main.hx", lineNumber: 153, className: "Main", methodName: "main"})
  circle.setVelocity(1, 2)
  circle.update(1.5)
  Log.trace(circle.draw(), %{fileName: "Main.hx", lineNumber: 156, className: "Main", methodName: "main"})
  unit_circle = Circle.createUnit()
  Log.trace(unit_circle.draw(), %{fileName: "Main.hx", lineNumber: 160, className: "Main", methodName: "main"})
  container = Container.new()
  container.add("Hello")
  container.add("World")
  Log.trace(container.get(0), %{fileName: "Main.hx", lineNumber: 166, className: "Main", methodName: "main"})
  Log.trace(container.size(), %{fileName: "Main.hx", lineNumber: 167, className: "Main", methodName: "main"})
  lengths = container.map(fn s -> s.length end)
  Log.trace(lengths.get(0), %{fileName: "Main.hx", lineNumber: 171, className: "Main", methodName: "main"})
)
  end

end
