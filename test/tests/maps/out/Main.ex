defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Map/Dictionary test case
 * Tests various map types and operations
 
  """

  # Static functions
  @doc "Function string_map"
  @spec string_map() :: TAbstract(Void,[]).t()
  def string_map() do
    (
  map = # TODO: Implement expression type: TNew
  map.set("one", 1)
  map.set("two", 2)
  map.set("three", 3)
  Log.trace("Value of "two": " + map.get("two"), %{fileName: "Main.hx", lineNumber: 18, className: "Main", methodName: "stringMap"})
  Log.trace("Value of "four": " + map.get("four"), %{fileName: "Main.hx", lineNumber: 19, className: "Main", methodName: "stringMap"})
  Log.trace("Has "one": " + Std.string(map.exists("one")), %{fileName: "Main.hx", lineNumber: 22, className: "Main", methodName: "stringMap"})
  Log.trace("Has "four": " + Std.string(map.exists("four")), %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "stringMap"})
  map.remove("two")
  Log.trace("After remove, has "two": " + Std.string(map.exists("two")), %{fileName: "Main.hx", lineNumber: 27, className: "Main", methodName: "stringMap"})
  Log.trace("Iterating string map:", %{fileName: "Main.hx", lineNumber: 30, className: "Main", methodName: "stringMap"})
  (
  key = map.keys()
  # TODO: Implement expression type: TWhile
)
  map.clear()
  temp_array = nil
  (
  _g = []
  (
  k = map.keys()
  # TODO: Implement expression type: TWhile
)
  temp_array = _g
)
  Log.trace("After clear, keys: " + Std.string(temp_array), %{fileName: "Main.hx", lineNumber: 37, className: "Main", methodName: "stringMap"})
)
  end

  @doc "Function int_map"
  @spec int_map() :: TAbstract(Void,[]).t()
  def int_map() do
    (
  map = # TODO: Implement expression type: TNew
  map.set(1, "first")
  map.set(2, "second")
  map.set(10, "tenth")
  map.set(100, "hundredth")
  Log.trace("Int map values:", %{fileName: "Main.hx", lineNumber: 49, className: "Main", methodName: "intMap"})
  (
  key = map.keys()
  # TODO: Implement expression type: TWhile
)
  temp_array = nil
  (
  _g = []
  (
  k = map.keys()
  # TODO: Implement expression type: TWhile
)
  temp_array = _g
)
  keys = temp_array
  temp_array1 = nil
  (
  _g = []
  (
  k = map.keys()
  # TODO: Implement expression type: TWhile
)
  temp_array1 = _g
)
  values = temp_array1
  Log.trace("Keys: " + Std.string(keys), %{fileName: "Main.hx", lineNumber: 57, className: "Main", methodName: "intMap"})
  Log.trace("Values: " + Std.string(values), %{fileName: "Main.hx", lineNumber: 58, className: "Main", methodName: "intMap"})
)
  end

  @doc "Function object_map"
  @spec object_map() :: TAbstract(Void,[]).t()
  def object_map() do
    (
  map = # TODO: Implement expression type: TNew
  obj1 = %{id: 1}
  obj2 = %{id: 2}
  map.set(obj1, "Object 1")
  map.set(obj2, "Object 2")
  Log.trace("Object 1 value: " + map.get(obj1), %{fileName: "Main.hx", lineNumber: 71, className: "Main", methodName: "objectMap"})
  Log.trace("Object 2 value: " + map.get(obj2), %{fileName: "Main.hx", lineNumber: 72, className: "Main", methodName: "objectMap"})
  obj3 = %{id: 1}
  Log.trace("New {id: 1} value: " + map.get(obj3), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "objectMap"})
)
  end

  @doc "Function map_literals"
  @spec map_literals() :: TAbstract(Void,[]).t()
  def map_literals() do
    (
  temp_map = nil
  (
  _g = # TODO: Implement expression type: TNew
  _g.set("red", 16711680)
  _g.set("green", 65280)
  _g.set("blue", 255)
  temp_map = _g
)
  colors = temp_map
  Log.trace("Color values:", %{fileName: "Main.hx", lineNumber: 88, className: "Main", methodName: "mapLiterals"})
  (
  color = colors.keys()
  # TODO: Implement expression type: TWhile
)
  temp_map1 = nil
  (
  _g = # TODO: Implement expression type: TNew
  _g.set(1, 1)
  _g.set(2, 4)
  _g.set(3, 9)
  _g.set(4, 16)
  _g.set(5, 25)
  temp_map1 = _g
)
  squares = temp_map1
  Log.trace("Squares:", %{fileName: "Main.hx", lineNumber: 103, className: "Main", methodName: "mapLiterals"})
  (
  n = squares.keys()
  # TODO: Implement expression type: TWhile
)
)
  end

  @doc "Function nested_maps"
  @spec nested_maps() :: TAbstract(Void,[]).t()
  def nested_maps() do
    (
  users = # TODO: Implement expression type: TNew
  alice = # TODO: Implement expression type: TNew
  alice.set("age", # TODO: Implement expression type: TCast)
  alice.set("email", # TODO: Implement expression type: TCast)
  alice.set("active", # TODO: Implement expression type: TCast)
  bob = # TODO: Implement expression type: TNew
  bob.set("age", # TODO: Implement expression type: TCast)
  bob.set("email", # TODO: Implement expression type: TCast)
  bob.set("active", # TODO: Implement expression type: TCast)
  users.set("alice", alice)
  users.set("bob", bob)
  Log.trace("User data:", %{fileName: "Main.hx", lineNumber: 128, className: "Main", methodName: "nestedMaps"})
  (
  username = users.keys()
  # TODO: Implement expression type: TWhile
)
)
  end

  @doc "Function map_transformations"
  @spec map_transformations() :: TAbstract(Void,[]).t()
  def map_transformations() do
    (
  temp_map = nil
  (
  _g = # TODO: Implement expression type: TNew
  _g.set("a", 1)
  _g.set("b", 2)
  _g.set("c", 3)
  _g.set("d", 4)
  temp_map = _g
)
  original = temp_map
  doubled = # TODO: Implement expression type: TNew
  (
  key = original.keys()
  # TODO: Implement expression type: TWhile
)
  Log.trace("Doubled values:", %{fileName: "Main.hx", lineNumber: 153, className: "Main", methodName: "mapTransformations"})
  (
  key = doubled.keys()
  # TODO: Implement expression type: TWhile
)
  filtered = # TODO: Implement expression type: TNew
  (
  key = original.keys()
  # TODO: Implement expression type: TWhile
)
  Log.trace("Filtered (value > 2):", %{fileName: "Main.hx", lineNumber: 167, className: "Main", methodName: "mapTransformations"})
  (
  key = filtered.keys()
  # TODO: Implement expression type: TWhile
)
  temp_map1 = nil
  (
  _g = # TODO: Implement expression type: TNew
  _g.set("a", 1)
  _g.set("b", 2)
  temp_map1 = _g
)
  map1 = temp_map1
  temp_map2 = nil
  (
  _g = # TODO: Implement expression type: TNew
  _g.set("c", 3)
  _g.set("d", 4)
  _g.set("a", 10)
  temp_map2 = _g
)
  map2 = temp_map2
  merged = # TODO: Implement expression type: TNew
  (
  key = map1.keys()
  # TODO: Implement expression type: TWhile
)
  (
  key = map2.keys()
  # TODO: Implement expression type: TWhile
)
  Log.trace("Merged maps:", %{fileName: "Main.hx", lineNumber: 184, className: "Main", methodName: "mapTransformations"})
  (
  key = merged.keys()
  # TODO: Implement expression type: TWhile
)
)
  end

  @doc "Function enum_map"
  @spec enum_map() :: TAbstract(Void,[]).t()
  def enum_map() do
    (
  map = # TODO: Implement expression type: TNew
  map.set(Color.red(), "FF0000")
  map.set(Color.green(), "00FF00")
  map.set(Color.blue(), "0000FF")
  Log.trace("Enum map:", %{fileName: "Main.hx", lineNumber: 198, className: "Main", methodName: "enumMap"})
  (
  color = map.keys()
  # TODO: Implement expression type: TWhile
)
  if (map.exists(Color.red())), do: Log.trace("Red color code: #" + map.get(Color.red()), %{fileName: "Main.hx", lineNumber: 205, className: "Main", methodName: "enumMap"}), else: nil
)
  end

  @doc "Function process_map"
  @spec process_map(TType(Map,[TInst(String,[]),TAbstract(Int,[])]).t()) :: TType(Map,[TInst(String,[]),TInst(String,[])]).t()
  def process_map(arg0) do
    (
  result = # TODO: Implement expression type: TNew
  (
  key = input.keys()
  # TODO: Implement expression type: TWhile
)
  result
)
  end

  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("=== String Map ===", %{fileName: "Main.hx", lineNumber: 220, className: "Main", methodName: "main"})
  Main.string_map()
  Log.trace("
=== Int Map ===", %{fileName: "Main.hx", lineNumber: 223, className: "Main", methodName: "main"})
  Main.int_map()
  Log.trace("
=== Object Map ===", %{fileName: "Main.hx", lineNumber: 226, className: "Main", methodName: "main"})
  Main.object_map()
  Log.trace("
=== Map Literals ===", %{fileName: "Main.hx", lineNumber: 229, className: "Main", methodName: "main"})
  Main.map_literals()
  Log.trace("
=== Nested Maps ===", %{fileName: "Main.hx", lineNumber: 232, className: "Main", methodName: "main"})
  Main.nested_maps()
  Log.trace("
=== Map Transformations ===", %{fileName: "Main.hx", lineNumber: 235, className: "Main", methodName: "main"})
  Main.map_transformations()
  Log.trace("
=== Enum Map ===", %{fileName: "Main.hx", lineNumber: 238, className: "Main", methodName: "main"})
  Main.enum_map()
  Log.trace("
=== Map Functions ===", %{fileName: "Main.hx", lineNumber: 241, className: "Main", methodName: "main"})
  temp_map = nil
  (
  _g = # TODO: Implement expression type: TNew
  _g.set("x", 10)
  _g.set("y", 20)
  _g.set("z", 30)
  temp_map = _g
)
  input = temp_map
  output = Main.process_map(input)
  (
  key = output.keys()
  # TODO: Implement expression type: TWhile
)
)
  end

end


defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    :green |
    :blue

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

end
