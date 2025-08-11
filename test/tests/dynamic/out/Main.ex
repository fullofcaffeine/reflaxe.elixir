defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Dynamic type test case
 * Tests dynamic typing and runtime type checking
 
  """

  # Static functions
  @doc "Function dynamic_vars"
  @spec dynamic_vars() :: TAbstract(Void,[]).t()
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
  dyn = # TODO: Implement expression type: TFunction
  Log.trace(dyn(5), %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "dynamicVars"})
)
  end

  @doc "Function dynamic_field_access"
  @spec dynamic_field_access() :: TAbstract(Void,[]).t()
  def dynamic_field_access() do
    (
  obj = %{name: "Alice", age: 25, greet: # TODO: Implement expression type: TFunction}
  Log.trace(obj.name, %{fileName: "Main.hx", lineNumber: 34, className: "Main", methodName: "dynamicFieldAccess"})
  Log.trace(obj.age, %{fileName: "Main.hx", lineNumber: 35, className: "Main", methodName: "dynamicFieldAccess"})
  Log.trace(obj.greet(), %{fileName: "Main.hx", lineNumber: 36, className: "Main", methodName: "dynamicFieldAccess"})
  obj.city = "New York"
  Log.trace(obj.city, %{fileName: "Main.hx", lineNumber: 40, className: "Main", methodName: "dynamicFieldAccess"})
  Log.trace(obj.non_existent, %{fileName: "Main.hx", lineNumber: 43, className: "Main", methodName: "dynamicFieldAccess"})
)
  end

  @doc "Function dynamic_functions"
  @spec dynamic_functions() :: TAbstract(Void,[]).t()
  def dynamic_functions() do
    (
  fn = # TODO: Implement expression type: TFunction
  Log.trace(fn(10, 20), %{fileName: "Main.hx", lineNumber: 49, className: "Main", methodName: "dynamicFunctions"})
  fn = # TODO: Implement expression type: TFunction
  Log.trace(fn("hello"), %{fileName: "Main.hx", lineNumber: 52, className: "Main", methodName: "dynamicFunctions"})
  var_args = # TODO: Implement expression type: TFunction
  Log.trace(var_args([1, 2, 3, 4, 5]), %{fileName: "Main.hx", lineNumber: 62, className: "Main", methodName: "dynamicFunctions"})
)
  end

  @doc "Function type_checking"
  @spec type_checking() :: TAbstract(Void,[]).t()
  def type_checking() do
    (
  value = 42
  if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: Log.trace("It's an Int: " + Std.string(value), %{fileName: "Main.hx", lineNumber: 71, className: "Main", methodName: "typeChecking"}), else: nil
  value = "Hello"
  if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: Log.trace("It's a String: " + Std.string(value), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "typeChecking"}), else: nil
  value = [1, 2, 3]
  if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: Log.trace("It's an Array with length: " + Std.string(value.length), %{fileName: "Main.hx", lineNumber: 81, className: "Main", methodName: "typeChecking"}), else: nil
  num = "123"
  int_value = Std.parse_int(num)
  Log.trace("Parsed int: " + int_value, %{fileName: "Main.hx", lineNumber: 87, className: "Main", methodName: "typeChecking"})
  float_value = Std.parse_float("3.14")
  Log.trace("Parsed float: " + float_value, %{fileName: "Main.hx", lineNumber: 90, className: "Main", methodName: "typeChecking"})
)
  end

  @doc "Function dynamic_generics"
  @spec dynamic_generics(TDynamic(null).t()) :: TInst(dynamicGenerics.T,[]).t()
  def dynamic_generics(arg0) do
    # TODO: Implement expression type: TCast
  end

  @doc "Function dynamic_collections"
  @spec dynamic_collections() :: TAbstract(Void,[]).t()
  def dynamic_collections() do
    (
  dyn_array = [1, "two", 3.0, true, %{x: 10}]
  (
  _g = 0
  # TODO: Implement expression type: TWhile
)
  dyn_obj = %{}
  dyn_obj.field1 = "value1"
  dyn_obj.field2 = 42
  dyn_obj.field3 = [1, 2, 3]
  Log.trace(dyn_obj, %{fileName: "Main.hx", lineNumber: 113, className: "Main", methodName: "dynamicCollections"})
)
  end

  @doc "Function process_dynamic"
  @spec process_dynamic(TDynamic(null).t()) :: TInst(String,[]).t()
  def process_dynamic(arg0) do
    if (value == nil), do: "null", else: if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: "Bool: " + Std.string(value), else: if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: "Int: " + Std.string(value), else: if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: "Float: " + Std.string(value), else: if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: "String: " + Std.string(value), else: if (Std.is_of_type(value, # TODO: Implement expression type: TTypeExpr)), do: "Array of length: " + Std.string(value.length), else: "Unknown type"
  end

  @doc "Function dynamic_method_calls"
  @spec dynamic_method_calls() :: TAbstract(Void,[]).t()
  def dynamic_method_calls() do
    (
  obj = %{}
  obj.value = 10
  obj.increment = # TODO: Implement expression type: TFunction
  obj.get_value = # TODO: Implement expression type: TFunction
  Log.trace("Initial value: " + Std.string(obj.get_value()), %{fileName: "Main.hx", lineNumber: 146, className: "Main", methodName: "dynamicMethodCalls"})
  obj.increment()
  Log.trace("After increment: " + Std.string(obj.get_value()), %{fileName: "Main.hx", lineNumber: 148, className: "Main", methodName: "dynamicMethodCalls"})
  method_name = "increment"
  Reflect.call_method(obj, Reflect.field(obj, method_name), [])
  Log.trace("After reflect call: " + Std.string(obj.get_value()), %{fileName: "Main.hx", lineNumber: 153, className: "Main", methodName: "dynamicMethodCalls"})
)
  end

  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("=== Dynamic Variables ===", %{fileName: "Main.hx", lineNumber: 157, className: "Main", methodName: "main"})
  Main.dynamic_vars()
  Log.trace("
=== Dynamic Field Access ===", %{fileName: "Main.hx", lineNumber: 160, className: "Main", methodName: "main"})
  Main.dynamic_field_access()
  Log.trace("
=== Dynamic Functions ===", %{fileName: "Main.hx", lineNumber: 163, className: "Main", methodName: "main"})
  Main.dynamic_functions()
  Log.trace("
=== Type Checking ===", %{fileName: "Main.hx", lineNumber: 166, className: "Main", methodName: "main"})
  Main.type_checking()
  Log.trace("
=== Dynamic Collections ===", %{fileName: "Main.hx", lineNumber: 169, className: "Main", methodName: "main"})
  Main.dynamic_collections()
  Log.trace("
=== Process Dynamic ===", %{fileName: "Main.hx", lineNumber: 172, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic(nil), %{fileName: "Main.hx", lineNumber: 173, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic(true), %{fileName: "Main.hx", lineNumber: 174, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic(42), %{fileName: "Main.hx", lineNumber: 175, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic(3.14), %{fileName: "Main.hx", lineNumber: 176, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic("Hello"), %{fileName: "Main.hx", lineNumber: 177, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic([1, 2, 3]), %{fileName: "Main.hx", lineNumber: 178, className: "Main", methodName: "main"})
  Log.trace(Main.process_dynamic(%{x: 1, y: 2}), %{fileName: "Main.hx", lineNumber: 179, className: "Main", methodName: "main"})
  Log.trace("
=== Dynamic Method Calls ===", %{fileName: "Main.hx", lineNumber: 181, className: "Main", methodName: "main"})
  Main.dynamic_method_calls()
  Log.trace("
=== Dynamic Generics ===", %{fileName: "Main.hx", lineNumber: 184, className: "Main", methodName: "main"})
  str = Main.dynamic_generics("Hello from dynamic")
  Log.trace(str, %{fileName: "Main.hx", lineNumber: 186, className: "Main", methodName: "main"})
)
  end

end
