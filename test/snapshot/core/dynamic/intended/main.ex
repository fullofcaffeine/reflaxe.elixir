defmodule Main do
  def dynamic_vars() do
    dyn = 42
    Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = "Hello"
    Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = [1, 2, 3]
    Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = %{:name => "John", :age => 30}
    Log.trace(dyn, %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "dynamicVars"})
    dyn = fn x -> x * 2 end
    Log.trace(dyn.(5), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "dynamicVars"})
  end

  def dynamic_field_access() do
    obj = %{:name => "Alice", :age => 25, :greet => fn -> "Hello!" end}
    Log.trace(Map.get(obj, :name), %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    Log.trace(Map.get(obj, :age), %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    greet_fn = Map.get(obj, :greet)
    Log.trace(greet_fn.(), %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    _city = "New York"
    Log.trace(Map.get(obj, :city), %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "dynamicFieldAccess"})
    Log.trace(Map.get(obj, :non_existent), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "dynamicFieldAccess"})
  end

  def dynamic_functions() do
    fn_param = fn a, b -> a + b end
    Log.trace(fn_param.(10, 20), %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "dynamicFunctions"})
    fn_param = fn s -> String.upcase(s) end
    Log.trace(fn_param.("hello"), %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "dynamicFunctions"})
    var_args = fn args ->
      Enum.sum(args)
    end
    Log.trace(var_args.([1, 2, 3, 4, 5]), %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "dynamicFunctions"})
  end

  def type_checking() do
    value = 42
    if is_integer(value) do
      Log.trace("It's an Int: #{value}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "typeChecking"})
    end
    value = "Hello"
    if is_binary(value) do
      Log.trace("It's a String: #{value}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "typeChecking"})
    end
    value = [1, 2, 3]
    if is_list(value) do
      Log.trace("It's an Array with length: #{length(value)}", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "typeChecking"})
    end
    num = "123"
    int_value = String.to_integer(num)
    Log.trace("Parsed int: #{int_value}", %{:file_name => "Main.hx", :line_number => 87, :class_name => "Main", :method_name => "typeChecking"})
    float_value = String.to_float("3.14")
    Log.trace("Parsed float: #{float_value}", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "typeChecking"})
  end

  def dynamic_generics(value) do
    value
  end

  def dynamic_collections() do
    dyn_array = [1, "two", 3, true, %{:x => 10}]
    Enum.each(dyn_array, fn item ->
      Log.trace("Item: #{inspect(item)}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "dynamicCollections"})
    end)
    dyn_obj = %{}
    _field1 = "value1"
    _field2 = 42
    _field3 = [1, 2, 3]
    Log.trace(dyn_obj, %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "dynamicCollections"})
  end

  def process_dynamic(value) do
    cond do
      value == nil -> "null"
      is_boolean(value) -> "Bool: #{value}"
      is_integer(value) -> "Int: #{value}"
      is_float(value) -> "Float: #{value}"
      is_binary(value) -> "String: #{value}"
      is_list(value) -> "Array of length: #{length(value)}"
      true -> "Unknown type"
    end
  end

  def dynamic_method_calls() do
    obj = %{:value => 10, :increment => fn obj -> Map.update(obj, :value, 0, &(&1 + 1)) end, :get_value => fn obj -> Map.get(obj, :value) end}
    get_value = Map.get(obj, :get_value)
    Log.trace("Initial value: #{get_value.(obj)}", %{:file_name => "Main.hx", :line_number => 146, :class_name => "Main", :method_name => "dynamicMethodCalls"})
    increment = Map.get(obj, :increment)
    obj = increment.(obj)
    Log.trace("After increment: #{get_value.(obj)}", %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "dynamicMethodCalls"})
    method_name = "increment"
    method = Map.get(obj, String.to_atom(method_name))
    obj = apply(method, [obj])
    Log.trace("After reflect call: #{get_value.(obj)}", %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "dynamicMethodCalls"})
  end

  def main() do
    Log.trace("=== Dynamic Variables ===", %{:file_name => "Main.hx", :line_number => 157, :class_name => "Main", :method_name => "main"})
    dynamic_vars()
    Log.trace("\n=== Dynamic Field Access ===", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "main"})
    dynamic_field_access()
    Log.trace("\n=== Dynamic Functions ===", %{:file_name => "Main.hx", :line_number => 163, :class_name => "Main", :method_name => "main"})
    dynamic_functions()
    Log.trace("\n=== Type Checking ===", %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "main"})
    type_checking()
    Log.trace("\n=== Dynamic Collections ===", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "main"})
    dynamic_collections()
    Log.trace("\n=== Process Dynamic ===", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic(nil), %{:file_name => "Main.hx", :line_number => 173, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic(true), %{:file_name => "Main.hx", :line_number => 174, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic(42), %{:file_name => "Main.hx", :line_number => 175, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic(3.14), %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic("Hello"), %{:file_name => "Main.hx", :line_number => 177, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 178, :class_name => "Main", :method_name => "main"})
    Log.trace(process_dynamic(%{:x => 1, :y => 2}), %{:file_name => "Main.hx", :line_number => 179, :class_name => "Main", :method_name => "main"})
    Log.trace("\n=== Dynamic Method Calls ===", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "main"})
    dynamic_method_calls()
    Log.trace("\n=== Dynamic Generics ===", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "main"})
    str = dynamic_generics("Hello from dynamic")
    Log.trace(str, %{:file_name => "Main.hx", :line_number => 186, :class_name => "Main", :method_name => "main"})
  end
end