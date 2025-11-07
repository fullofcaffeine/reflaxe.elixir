defmodule Main do
  def main() do
    _ = test_field_operations()
    _ = test_field_listing()
    _ = test_object_checking()
    _ = test_comparison()
    _ = test_enum_detection()
    _ = test_method_calling()
  end
  defp test_field_operations() do
    obj = %{:name => "Alice", :age => 30, :active => true}
    nested = %{:user => %{:id => 1, :name => "Bob"}, :settings => %{:theme => "dark", :notifications => true}}
    _name = Map.get(obj, "name")
    _age = Map.get(obj, "age")
    _missing = Map.get(obj, "nonexistent")
    _nested_name = Map.get(Map.get(nested, "user"), "name")
    _ = Log.trace("Field retrieval:", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  obj.name: #{(fn -> name end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  obj.age: #{(fn -> age end).()}", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  obj.nonexistent: #{(fn -> missing end).()}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  nested.user.name: #{(fn -> nested_name end).()}", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testFieldOperations"})
    updated = Map.put(obj, "age", 31)
    new_field = Map.put(obj, "city", "New York")
    _ = Log.trace("Field setting (immutable):", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  Updated age: #{(fn -> inspect(Map.get(updated, "age")) end).()}", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  New field city: #{(fn -> inspect(Map.get(new_field, "city")) end).()}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testFieldOperations"})
    has_name = Map.has_key?(obj, "name")
    has_city = Map.has_key?(obj, "city")
    has_nested = Map.has_key?(nested, "user")
    _ = Log.trace("Field existence:", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  Has name: #{(fn -> inspect(has_name) end).()}", %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  Has city: #{(fn -> inspect(has_city) end).()}", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  Has user: #{(fn -> inspect(has_nested) end).()}", %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "testFieldOperations"})
    deleted = Reflect.delete_field(obj, "age")
    deleted_missing = Reflect.delete_field(obj, "nonexistent")
    _ = Log.trace("Field deletion:", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  After deleting age: #{(fn -> inspect(Map.has_key?(deleted, "age")) end).()}", %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testFieldOperations"})
    _ = Log.trace("  Delete nonexistent: #{(fn -> inspect(Map.get(deleted_missing, "name")) end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testFieldOperations"})
  end
  defp test_field_listing() do
    simple = %{:x => 10, :y => 20}
    complex = %{:id => 1, :name => "Test", :active => true, :data => [1, 2, 3], :meta => %{:created => "2024-01-01"}}
    empty = %{}
    simple_fields = Reflect.fields(simple)
    complex_fields = Reflect.fields(complex)
    empty_fields = Reflect.fields(empty)
    _ = Log.trace("Field listing:", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "testFieldListing"})
    _ = Log.trace("  Simple object fields: [#{(fn -> Enum.join((fn -> simple_fields end).(), ", ") end).()}]", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "testFieldListing"})
    _ = Log.trace("  Complex object fields: [#{(fn -> Enum.join((fn -> complex_fields end).(), ", ") end).()}]", %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testFieldListing"})
    _ = Log.trace("  Empty object fields: [#{(fn -> Enum.join((fn -> empty_fields end).(), ", ") end).()}]", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "testFieldListing"})
  end
  defp test_object_checking() do
    obj = %{:field => "value"}
    str = "string"
    num = 42
    arr = [1, 2, 3]
    nul = nil
    fun = fn x -> x * 2 end
    obj_is_object = Reflect.is_object(obj)
    str_is_object = Reflect.is_object(str)
    num_is_object = Reflect.is_object(num)
    arr_is_object = Reflect.is_object(arr)
    null_is_object = Reflect.is_object(nul)
    fun_is_object = Reflect.is_object(fun)
    _ = Log.trace("Object type checking:", %{:file_name => "Main.hx", :line_number => 100, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Object is object: #{(fn -> inspect(obj_is_object) end).()}", %{:file_name => "Main.hx", :line_number => 101, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  String is object: #{(fn -> inspect(str_is_object) end).()}", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Number is object: #{(fn -> inspect(num_is_object) end).()}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Array is object: #{(fn -> inspect(arr_is_object) end).()}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Null is object: #{(fn -> inspect(null_is_object) end).()}", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Function is object: #{(fn -> inspect(fun_is_object) end).()}", %{:file_name => "Main.hx", :line_number => 106, :class_name => "Main", :method_name => "testObjectChecking"})
    original = %{:a => 1, :b => %{:c => 2}}
    _ = Log.trace("Object copying:", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Original a: #{(fn -> inspect(Map.get(original, "a")) end).()}", %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testObjectChecking"})
    _ = Log.trace("  Copied a: #{(fn -> inspect(Map.get(original, "a")) end).()}", %{:file_name => "Main.hx", :line_number => 114, :class_name => "Main", :method_name => "testObjectChecking"})
  end
  defp test_comparison() do
    cmp_ints = Reflect.compare(5, 10)
    cmp_equal = Reflect.compare(42, 42)
    cmp_strings = Reflect.compare("apple", "banana")
    cmp_floats = Reflect.compare(3.14, 2.71)
    cmp_bools = Reflect.compare(true, false)
    cmp_arrays = Reflect.compare([1, 2], [1, 3])
    _ = Log.trace("Value comparison:", %{:file_name => "Main.hx", :line_number => 126, :class_name => "Main", :method_name => "testComparison"})
    _ = Log.trace("  5 vs 10: #{(fn -> cmp_ints end).()}", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testComparison"})
    _ = Log.trace("  42 vs 42: #{(fn -> cmp_equal end).()}", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testComparison"})
    _ = Log.trace("  \"apple\" vs \"banana\": #{(fn -> cmp_strings end).()}", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testComparison"})
    _ = Log.trace("  3.14 vs 2.71: #{(fn -> cmp_floats end).()}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "testComparison"})
    _ = Log.trace("  true vs false: #{(fn -> cmp_bools end).()}", %{:file_name => "Main.hx", :line_number => 131, :class_name => "Main", :method_name => "testComparison"})
    _ = Log.trace("  [1,2] vs [1,3]: #{(fn -> cmp_arrays end).()}", %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "testComparison"})
  end
  defp test_enum_detection() do
    opt1 = {:some, "value"}
    opt2 = {:none}
    res1 = {:ok, 42}
    res2 = {:error, "failed"}
    str = "not an enum"
    obj = %{:field => "value"}
    num = 123
    opt1_is_enum = Reflect.is_enum_value(opt1)
    opt2_is_enum = Reflect.is_enum_value(opt2)
    res1_is_enum = Reflect.is_enum_value(res1)
    res2_is_enum = Reflect.is_enum_value(res2)
    str_is_enum = Reflect.is_enum_value(str)
    obj_is_enum = Reflect.is_enum_value(obj)
    num_is_enum = Reflect.is_enum_value(num)
    _ = Log.trace("Enum value detection:", %{:file_name => "Main.hx", :line_number => 154, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  Some(\"value\") is enum: #{(fn -> inspect(opt1_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  None is enum: #{(fn -> inspect(opt2_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  Ok(42) is enum: #{(fn -> inspect(res1_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 157, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  Error(\"failed\") is enum: #{(fn -> inspect(res2_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  String is enum: #{(fn -> inspect(str_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 159, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  Object is enum: #{(fn -> inspect(obj_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "testEnumDetection"})
    _ = Log.trace("  Number is enum: #{(fn -> inspect(num_is_enum) end).()}", %{:file_name => "Main.hx", :line_number => 161, :class_name => "Main", :method_name => "testEnumDetection"})
  end
  defp test_method_calling() do
    add = fn a, b -> a + b end
    multiply = fn x, y -> x * y end
    greet = fn name -> "Hello, " <> name <> "!" end
    no_args = fn -> "No arguments" end
    sum = Reflect.call_method(nil, add, [10, 20])
    product = Reflect.call_method(nil, multiply, [5, 6])
    greeting = Reflect.call_method(nil, greet, ["World"])
    no_args_result = Reflect.call_method(nil, no_args, [])
    _ = Log.trace("Dynamic method calling:", %{:file_name => "Main.hx", :line_number => 188, :class_name => "Main", :method_name => "testMethodCalling"})
    _ = Log.trace("  add(10, 20): #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "testMethodCalling"})
    _ = Log.trace("  multiply(5, 6): #{(fn -> product end).()}", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "testMethodCalling"})
    _ = Log.trace("  greet(\"World\"): #{(fn -> greeting end).()}", %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "testMethodCalling"})
    _ = Log.trace("  noArgs(): #{(fn -> no_args_result end).()}", %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "testMethodCalling"})
    calculator = %{:value => 100, :add_to => fn n -> n + 100 end, :multiply_by => fn n -> n * 2 end}
    added = Reflect.call_method(calculator, Map.get(calculator, "addTo"), [50])
    multiplied = Reflect.call_method(calculator, Map.get(calculator, "multiplyBy"), [25])
    _ = Log.trace("Object method calling:", %{:file_name => "Main.hx", :line_number => 208, :class_name => "Main", :method_name => "testMethodCalling"})
    _ = Log.trace("  calculator.addTo(50): #{(fn -> added end).()}", %{:file_name => "Main.hx", :line_number => 209, :class_name => "Main", :method_name => "testMethodCalling"})
    _ = Log.trace("  calculator.multiplyBy(25): #{(fn -> multiplied end).()}", %{:file_name => "Main.hx", :line_number => 210, :class_name => "Main", :method_name => "testMethodCalling"})
  end
end
