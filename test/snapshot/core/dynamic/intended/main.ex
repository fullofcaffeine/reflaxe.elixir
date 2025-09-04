defmodule Main do
  def dynamic_vars() do
    dyn = 42
    Log.trace(dyn, %{:fileName => "Main.hx", :lineNumber => 11, :className => "Main", :methodName => "dynamicVars"})
    dyn = "Hello"
    Log.trace(dyn, %{:fileName => "Main.hx", :lineNumber => 14, :className => "Main", :methodName => "dynamicVars"})
    dyn = [1, 2, 3]
    Log.trace(dyn, %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "dynamicVars"})
    dyn = %{:name => "John", :age => 30}
    Log.trace(dyn, %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "dynamicVars"})
    dyn = fn x -> x * 2 end
    Log.trace(dyn(5), %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "dynamicVars"})
  end
  def dynamic_field_access() do
    obj = %{:name => "Alice", :age => 25, :greet => fn -> "Hello!" end}
    Log.trace(obj.name, %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "dynamicFieldAccess"})
    Log.trace(obj.age, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "dynamicFieldAccess"})
    Log.trace(obj.greet(), %{:fileName => "Main.hx", :lineNumber => 36, :className => "Main", :methodName => "dynamicFieldAccess"})
    city = "New York"
    Log.trace(obj.city, %{:fileName => "Main.hx", :lineNumber => 40, :className => "Main", :methodName => "dynamicFieldAccess"})
    Log.trace(obj.nonExistent, %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "dynamicFieldAccess"})
  end
  def dynamic_functions() do
    fn = fn a, b -> a + b end
    Log.trace(fn(10, 20), %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "dynamicFunctions"})
    fn = fn s -> s.toUpperCase() end
    Log.trace(fn("hello"), %{:fileName => "Main.hx", :lineNumber => 52, :className => "Main", :methodName => "dynamicFunctions"})
    var_args = fn args ->
  sum = 0
  g = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, args, g, :ok}, fn _, {acc_sum, acc_args, acc_g, acc_state} ->
  if (acc_g < acc_args.length) do
    arg = args[g]
    acc_g = acc_g + 1
    acc_sum = acc_sum + arg
    {:cont, {acc_sum, acc_args, acc_g, acc_state}}
  else
    {:halt, {acc_sum, acc_args, acc_g, acc_state}}
  end
end)
  sum
end
    Log.trace(var_args([1, 2, 3, 4, 5]), %{:fileName => "Main.hx", :lineNumber => 62, :className => "Main", :methodName => "dynamicFunctions"})
  end
  def type_checking() do
    value = 42
    if (Std.is(value, Int)) do
      Log.trace("It's an Int: " <> Std.string(value), %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "typeChecking"})
    end
    value = "Hello"
    if (Std.is(value, String)) do
      Log.trace("It's a String: " <> Std.string(value), %{:fileName => "Main.hx", :lineNumber => 76, :className => "Main", :methodName => "typeChecking"})
    end
    value = [1, 2, 3]
    if (Std.is(value, Array)) do
      Log.trace("It's an Array with length: " <> Std.string(value.length), %{:fileName => "Main.hx", :lineNumber => 81, :className => "Main", :methodName => "typeChecking"})
    end
    num = "123"
    int_value = Std.parse_int(num)
    Log.trace("Parsed int: " <> int_value, %{:fileName => "Main.hx", :lineNumber => 87, :className => "Main", :methodName => "typeChecking"})
    float_value = Std.parse_float("3.14")
    Log.trace("Parsed float: " <> float_value, %{:fileName => "Main.hx", :lineNumber => 90, :className => "Main", :methodName => "typeChecking"})
  end
  def dynamic_generics(value) do
    value
  end
  def dynamic_collections() do
    dyn_array = [1, "two", 3, true, %{:x => 10}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, dyn_array, :ok}, fn _, {acc_g, acc_dyn_array, acc_state} ->
  if (acc_g < acc_dyn_array.length) do
    item = dyn_array[g]
    acc_g = acc_g + 1
    Log.trace("Item: " <> Std.string(item), %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "dynamicCollections"})
    {:cont, {acc_g, acc_dyn_array, acc_state}}
  else
    {:halt, {acc_g, acc_dyn_array, acc_state}}
  end
end)
    dyn_obj = %{}
    field1 = "value1"
    field2 = 42
    field3 = [1, 2, 3]
    Log.trace(dyn_obj, %{:fileName => "Main.hx", :lineNumber => 113, :className => "Main", :methodName => "dynamicCollections"})
  end
  def process_dynamic(value) do
    if (value == nil) do
      "null"
    else
      if (Std.is(value, Bool)) do
        "Bool: " <> Std.string(value)
      else
        if (Std.is(value, Int)) do
          "Int: " <> Std.string(value)
        else
          if (Std.is(value, Float)) do
            "Float: " <> Std.string(value)
          else
            if (Std.is(value, String)) do
              "String: " <> Std.string(value)
            else
              if (Std.is(value, Array)) do
                "Array of length: " <> Std.string(value.length)
              else
                "Unknown type"
              end
            end
          end
        end
      end
    end
  end
  def dynamic_method_calls() do
    obj = %{}
    value = 10
    increment = fn -> obj.value + 1 end
    getValue = fn -> obj.value end
    Log.trace("Initial value: " <> Std.string(obj.getValue()), %{:fileName => "Main.hx", :lineNumber => 146, :className => "Main", :methodName => "dynamicMethodCalls"})
    obj.increment()
    Log.trace("After increment: " <> Std.string(obj.getValue()), %{:fileName => "Main.hx", :lineNumber => 148, :className => "Main", :methodName => "dynamicMethodCalls"})
    method_name = "increment"
    Reflect.call_method(obj, Reflect.field(obj, method_name), [])
    Log.trace("After reflect call: " <> Std.string(obj.getValue()), %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "dynamicMethodCalls"})
  end
  def main() do
    Log.trace("=== Dynamic Variables ===", %{:fileName => "Main.hx", :lineNumber => 157, :className => "Main", :methodName => "main"})
    dynamic_vars()
    Log.trace("\n=== Dynamic Field Access ===", %{:fileName => "Main.hx", :lineNumber => 160, :className => "Main", :methodName => "main"})
    dynamic_field_access()
    Log.trace("\n=== Dynamic Functions ===", %{:fileName => "Main.hx", :lineNumber => 163, :className => "Main", :methodName => "main"})
    dynamic_functions()
    Log.trace("\n=== Type Checking ===", %{:fileName => "Main.hx", :lineNumber => 166, :className => "Main", :methodName => "main"})
    type_checking()
    Log.trace("\n=== Dynamic Collections ===", %{:fileName => "Main.hx", :lineNumber => 169, :className => "Main", :methodName => "main"})
    dynamic_collections()
    Log.trace("\n=== Process Dynamic ===", %{:fileName => "Main.hx", :lineNumber => 172, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic(nil), %{:fileName => "Main.hx", :lineNumber => 173, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic(true), %{:fileName => "Main.hx", :lineNumber => 174, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic(42), %{:fileName => "Main.hx", :lineNumber => 175, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic(3.14), %{:fileName => "Main.hx", :lineNumber => 176, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic("Hello"), %{:fileName => "Main.hx", :lineNumber => 177, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic([1, 2, 3]), %{:fileName => "Main.hx", :lineNumber => 178, :className => "Main", :methodName => "main"})
    Log.trace(process_dynamic(%{:x => 1, :y => 2}), %{:fileName => "Main.hx", :lineNumber => 179, :className => "Main", :methodName => "main"})
    Log.trace("\n=== Dynamic Method Calls ===", %{:fileName => "Main.hx", :lineNumber => 181, :className => "Main", :methodName => "main"})
    dynamic_method_calls()
    Log.trace("\n=== Dynamic Generics ===", %{:fileName => "Main.hx", :lineNumber => 184, :className => "Main", :methodName => "main"})
    str = dynamic_generics("Hello from dynamic")
    Log.trace(str, %{:fileName => "Main.hx", :lineNumber => 186, :className => "Main", :methodName => "main"})
  end
end