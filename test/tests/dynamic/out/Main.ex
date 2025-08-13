defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Dynamic type test case
 * Tests dynamic typing and runtime type checking
 
  """

  # Static functions
  @doc "Function dynamic_vars"
  @spec dynamic_vars() :: nil
  def dynamic_vars() do
    (
  dyn = 42
  Log.trace(dyn, %{fileName: "Main.hx", lineNumber: 11, className: "Main", methodName: "dynamicVars"})
  dyn = "Hello"
  Log.trace(dyn, %{fileName: "Main.hx", lineNumber: 14, className: "Main", methodName: "dynamicVars"})
  dyn = [1, 2, 3]
  Log.trace(dyn, %{fileName: "Main.hx", lineNumber: 17, className: "Main", methodName: "dynamicVars"})
  dyn = %{name: "John", age: 30}
  Log.trace(dyn, %{fileName: "Main.hx", lineNumber: 20, className: "Main", methodName: "dynamicVars"})
  dyn = fn x -> x * 2 end
  Log.trace(dyn(5), %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "dynamicVars"})
)
  end

  @doc "Function dynamic_field_access"
  @spec dynamic_field_access() :: nil
  def dynamic_field_access() do
    (
  obj = %{name: "Alice", age: 25, greet: fn  -> "Hello!" end}
  Log.trace(obj.name, %{fileName: "Main.hx", lineNumber: 34, className: "Main", methodName: "dynamicFieldAccess"})
  Log.trace(obj.age, %{fileName: "Main.hx", lineNumber: 35, className: "Main", methodName: "dynamicFieldAccess"})
  Log.trace(obj.greet(), %{fileName: "Main.hx", lineNumber: 36, className: "Main", methodName: "dynamicFieldAccess"})
  obj.city = "New York"
  Log.trace(obj.city, %{fileName: "Main.hx", lineNumber: 40, className: "Main", methodName: "dynamicFieldAccess"})
  Log.trace(obj.non_existent, %{fileName: "Main.hx", lineNumber: 43, className: "Main", methodName: "dynamicFieldAccess"})
)
  end

  @doc "Function dynamic_functions"
  @spec dynamic_functions() :: nil
  def dynamic_functions() do
    (
  fn = fn a, b -> a + b end
  Log.trace(fn(10, 20), %{fileName: "Main.hx", lineNumber: 49, className: "Main", methodName: "dynamicFunctions"})
  fn = fn s -> s.toUpperCase() end
  Log.trace(fn("hello"), %{fileName: "Main.hx", lineNumber: 52, className: "Main", methodName: "dynamicFunctions"})
  var_args = fn args -> (
  sum = 0
  (
  _g = 0
  while (_g < args.length) do
  (
  arg = Enum.at(args, _g)
  _g + 1
  sum += arg
)
end
)
  sum
) end
  Log.trace(var_args([1, 2, 3, 4, 5]), %{fileName: "Main.hx", lineNumber: 62, className: "Main", methodName: "dynamicFunctions"})
)
  end

  @doc "Function type_checking"
  @spec type_checking() :: nil
  def type_checking() do
    (
  value = 42
  if (Std.isOfType(value, Int)), do: Log.trace("It's an Int: " + Std.string(value), %{fileName: "Main.hx", lineNumber: 71, className: "Main", methodName: "typeChecking"}), else: nil
  value = "Hello"
  if (Std.isOfType(value, String)), do: Log.trace("It's a String: " + Std.string(value), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "typeChecking"}), else: nil
  value = [1, 2, 3]
  if (Std.isOfType(value, Array)), do: Log.trace("It's an Array with length: " + Std.string(value.length), %{fileName: "Main.hx", lineNumber: 81, className: "Main", methodName: "typeChecking"}), else: nil
  num = "123"
  int_value = Std.parseInt(num)
  Log.trace("Parsed int: " + int_value, %{fileName: "Main.hx", lineNumber: 87, className: "Main", methodName: "typeChecking"})
  float_value = Std.parseFloat("3.14")
  Log.trace("Parsed float: " + float_value, %{fileName: "Main.hx", lineNumber: 90, className: "Main", methodName: "typeChecking"})
)
  end

  @doc "Function dynamic_generics"
  @spec dynamic_generics(term()) :: T.t()
  def dynamic_generics(arg0) do
    value
  end

  @doc "Function dynamic_collections"
  @spec dynamic_collections() :: nil
  def dynamic_collections() do
    (
  dyn_array = [1, "two", 3.0, true, %{x: 10}]
  (
  _g = 0
  while (_g < dyn_array.length) do
  (
  item = Enum.at(dyn_array, _g)
  _g + 1
  Log.trace("Item: " + Std.string(item), %{fileName: "Main.hx", lineNumber: 103, className: "Main", methodName: "dynamicCollections"})
)
end
)
  dyn_obj = %{}
  dyn_obj.field1 = "value1"
  dyn_obj.field2 = 42
  dyn_obj.field3 = [1, 2, 3]
  Log.trace(dyn_obj, %{fileName: "Main.hx", lineNumber: 113, className: "Main", methodName: "dynamicCollections"})
)
  end

  @doc "Function process_dynamic"
  @spec process_dynamic(term()) :: String.t()
  def process_dynamic(arg0) do
    if (value == nil), do: "null", else: if (Std.isOfType(value, Bool)), do: "Bool: " + Std.string(value), else: if (Std.isOfType(value, Int)), do: "Int: " + Std.string(value), else: if (Std.isOfType(value, Float)), do: "Float: " + Std.string(value), else: if (Std.isOfType(value, String)), do: "String: " + Std.string(value), else: if (Std.isOfType(value, Array)), do: "Array of length: " + Std.string(value.length), else: "Unknown type"
  end

  @doc "Function dynamic_method_calls"
  @spec dynamic_method_calls() :: nil
  def dynamic_method_calls() do
    (
  obj = %{}
  obj.value = 10
  obj.increment = fn  -> obj.value + 1 end
  obj.get_value = fn  -> obj.value end
  Log.trace("Initial value: " + Std.string(obj.getValue()), %{fileName: "Main.hx", lineNumber: 146, className: "Main", methodName: "dynamicMethodCalls"})
  obj.increment()
  Log.trace("After increment: " + Std.string(obj.getValue()), %{fileName: "Main.hx", lineNumber: 148, className: "Main", methodName: "dynamicMethodCalls"})
  method_name = "increment"
  Reflect.callMethod(obj, Reflect.field(obj, method_name), [])
  Log.trace("After reflect call: " + Std.string(obj.getValue()), %{fileName: "Main.hx", lineNumber: 153, className: "Main", methodName: "dynamicMethodCalls"})
)
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
  Log.trace("=== Dynamic Variables ===", %{fileName: "Main.hx", lineNumber: 157, className: "Main", methodName: "main"})
  Main.dynamicVars()
  Log.trace("
=== Dynamic Field Access ===", %{fileName: "Main.hx", lineNumber: 160, className: "Main", methodName: "main"})
  Main.dynamicFieldAccess()
  Log.trace("
=== Dynamic Functions ===", %{fileName: "Main.hx", lineNumber: 163, className: "Main", methodName: "main"})
  Main.dynamicFunctions()
  Log.trace("
=== Type Checking ===", %{fileName: "Main.hx", lineNumber: 166, className: "Main", methodName: "main"})
  Main.typeChecking()
  Log.trace("
=== Dynamic Collections ===", %{fileName: "Main.hx", lineNumber: 169, className: "Main", methodName: "main"})
  Main.dynamicCollections()
  Log.trace("
=== Process Dynamic ===", %{fileName: "Main.hx", lineNumber: 172, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic(nil), %{fileName: "Main.hx", lineNumber: 173, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic(true), %{fileName: "Main.hx", lineNumber: 174, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic(42), %{fileName: "Main.hx", lineNumber: 175, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic(3.14), %{fileName: "Main.hx", lineNumber: 176, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic("Hello"), %{fileName: "Main.hx", lineNumber: 177, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic([1, 2, 3]), %{fileName: "Main.hx", lineNumber: 178, className: "Main", methodName: "main"})
  Log.trace(Main.processDynamic(%{x: 1, y: 2}), %{fileName: "Main.hx", lineNumber: 179, className: "Main", methodName: "main"})
  Log.trace("
=== Dynamic Method Calls ===", %{fileName: "Main.hx", lineNumber: 181, className: "Main", methodName: "main"})
  Main.dynamicMethodCalls()
  Log.trace("
=== Dynamic Generics ===", %{fileName: "Main.hx", lineNumber: 184, className: "Main", methodName: "main"})
  str = Main.dynamicGenerics("Hello from dynamic")
  Log.trace(str, %{fileName: "Main.hx", lineNumber: 186, className: "Main", methodName: "main"})
)
  end

end
