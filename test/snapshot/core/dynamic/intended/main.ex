defmodule Main do
  def dynamic_vars() do
    dyn = 42
    _ = Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = "Hello"
    _ = Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = [1, 2, 3]
    _ = Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = %{:name => "John", :age => 30}
    _ = Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = fn x -> x * 2 end
    _ = Log.trace(dyn.(5), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "dynamicVars"})
  end
  def dynamic_field_access() do
    obj = %{:name => "Alice", :age => 25, :greet => fn -> "Hello!" end}
    _ = Log.trace(Map.get(obj, :name), %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    _ = Log.trace(Map.get(obj, :age), %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    _ = Log.trace(Map.get(obj, :greet).(), %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    obj = Map.put(obj, "city", "New York")
    _ = Log.trace(Map.get(obj, :city), %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    _ = Log.trace(Map.get(obj, :non_existent), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "dynamicFieldAccess"})
  end
  def dynamic_functions() do
    fn_ = fn a, b -> a + b end
    fn_ = Log.trace(fn_.(10, 20), %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "dynamicFunctions"})
    fn_ = fn s -> String.upcase(s) end
    fn_ = Log.trace(fn_.("hello"), %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "dynamicFunctions"})
    var_args = fn args ->
      _g = 0
      _ = Enum.each(0..(length(args) - 1), (fn -> fn item ->
        arg = args[_g]
        item + 1
        sum = sum + arg
      end end).())
    end
    fn_ = Log.trace(var_args.([1, 2, 3, 4, 5]), %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "dynamicFunctions"})
    fn_
  end
  def type_checking() do
    value = 42
    if (MyApp.Std.is(value, Int)) do
      Log.trace("It's an Int: #{(fn -> inspect(value) end).()}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "typeChecking"})
    end
    value = "Hello"
    if (MyApp.Std.is(value, String)) do
      Log.trace("It's a String: #{(fn -> inspect(value) end).()}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "typeChecking"})
    end
    value = [1, 2, 3]
    if (MyApp.Std.is(value, Array)) do
      Log.trace("It's an Array with length: #{(fn -> length(value) end).()}", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "typeChecking"})
    end
    num = "123"
    int_value = String.to_integer(num)
    _ = Log.trace("Parsed int: #{(fn -> int_value end).()}", %{:file_name => "Main.hx", :line_number => 87, :class_name => "Main", :method_name => "typeChecking"})
    float_value = String.to_float("3.14")
    _ = Log.trace("Parsed float: #{(fn -> float_value end).()}", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "typeChecking"})
  end
  def dynamic_generics(value) do
    value
  end
  def dynamic_collections() do
    dyn_obj = dyn_obj |> Map.put("field1", "value1") |> Map.put("field2", 42) |> Map.put("field3", [1, 2, 3])
  end
  def process_dynamic(value) do
    cond do
      value == nil -> "null"
      Std.is(value, Bool) -> "Bool: " <> inspect(value)
      Std.is(value, Int) -> "Int: " <> inspect(value)
      Std.is(value, Float) -> "Float: " <> inspect(value)
      Std.is(value, String) -> "String: " <> inspect(value)
      Std.is(value, Array) -> "Array of length: " <> inspect(Map.get(value, :length))
      :true -> "Unknown type"
    end
  end
  def dynamic_method_calls() do
    obj = obj |> Map.put("value", 10) |> Map.put("increment", fn -> Map.get(obj, :value) + 1 end) |> Map.put("get_value", fn -> Map.get(obj, :value) end)
  end
  def main() do
    _ = Log.trace("=== Dynamic Variables ===", %{:file_name => "Main.hx", :line_number => 157, :class_name => "Main", :method_name => "main"})
    _ = dynamic_vars()
    _ = Log.trace("\n=== Dynamic Field Access ===", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "main"})
    _ = dynamic_field_access()
    _ = Log.trace("\n=== Dynamic Functions ===", %{:file_name => "Main.hx", :line_number => 163, :class_name => "Main", :method_name => "main"})
    _ = dynamic_functions()
    _ = Log.trace("\n=== Type Checking ===", %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "main"})
    _ = type_checking()
    _ = Log.trace("\n=== Dynamic Collections ===", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "main"})
    _ = dynamic_collections()
    _ = Log.trace("\n=== Process Dynamic ===", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic(nil), %{:file_name => "Main.hx", :line_number => 173, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic(true), %{:file_name => "Main.hx", :line_number => 174, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic(42), %{:file_name => "Main.hx", :line_number => 175, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic(3.14), %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic("Hello"), %{:file_name => "Main.hx", :line_number => 177, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 178, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_dynamic(%{:x => 1, :y => 2}), %{:file_name => "Main.hx", :line_number => 179, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("\n=== Dynamic Method Calls ===", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "main"})
    _ = dynamic_method_calls()
    _ = Log.trace("\n=== Dynamic Generics ===", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "main"})
    str = dynamic_generics("Hello from dynamic")
    _ = Log.trace(str, %{:file_name => "Main.hx", :line_number => 186, :class_name => "Main", :method_name => "main"})
  end
end
