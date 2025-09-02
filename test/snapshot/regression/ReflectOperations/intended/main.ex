defmodule Main do
  def main() do
    test_field_operations()
    test_field_listing()
    test_object_checking()
    test_comparison()
    test_enum_detection()
    test_method_calling()
  end
  defp test_field_operations() do
    obj = %{:name => "Alice", :age => 30, :active => true}
    nested = %{:user => %{:id => 1, :name => "Bob"}, :settings => %{:theme => "dark", :notifications => true}}
    name = Reflect.field(obj, "name")
    age = Reflect.field(obj, "age")
    missing = Reflect.field(obj, "nonexistent")
    nested_name = Reflect.field(Reflect.field(nested, "user"), "name")
    Log.trace("Field retrieval:", %{:fileName => "Main.hx", :lineNumber => 29, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  obj.name: " <> name, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  obj.age: " <> age, %{:fileName => "Main.hx", :lineNumber => 31, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  obj.nonexistent: " <> missing, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  nested.user.name: " <> nested_name, %{:fileName => "Main.hx", :lineNumber => 33, :className => "Main", :methodName => "testFieldOperations"})
    updated = Reflect.set_field(obj, "age", 31)
    new_field = Reflect.set_field(obj, "city", "New York")
    Log.trace("Field setting (immutable):", %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  Updated age: " <> Reflect.field(updated, "age"), %{:fileName => "Main.hx", :lineNumber => 40, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  New field city: " <> Reflect.field(new_field, "city"), %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "testFieldOperations"})
    has_name = Reflect.has_field(obj, "name")
    has_city = Reflect.has_field(obj, "city")
    has_nested = Reflect.has_field(nested, "user")
    Log.trace("Field existence:", %{:fileName => "Main.hx", :lineNumber => 48, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  Has name: " <> Std.string(has_name), %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  Has city: " <> Std.string(has_city), %{:fileName => "Main.hx", :lineNumber => 50, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  Has user: " <> Std.string(has_nested), %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "testFieldOperations"})
    deleted = Reflect.delete_field(obj, "age")
    deleted_missing = Reflect.delete_field(obj, "nonexistent")
    Log.trace("Field deletion:", %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  After deleting age: " <> Std.string(Reflect.has_field(deleted, "age")), %{:fileName => "Main.hx", :lineNumber => 58, :className => "Main", :methodName => "testFieldOperations"})
    Log.trace("  Delete nonexistent: " <> Reflect.field(deleted_missing, "name"), %{:fileName => "Main.hx", :lineNumber => 59, :className => "Main", :methodName => "testFieldOperations"})
  end
  defp test_field_listing() do
    simple = %{:x => 10, :y => 20}
    complex = %{:id => 1, :name => "Test", :active => true, :data => [1, 2, 3], :meta => %{:created => "2024-01-01"}}
    empty = %{}
    simple_fields = Reflect.fields(simple)
    complex_fields = Reflect.fields(complex)
    empty_fields = Reflect.fields(empty)
    Log.trace("Field listing:", %{:fileName => "Main.hx", :lineNumber => 78, :className => "Main", :methodName => "testFieldListing"})
    Log.trace("  Simple object fields: [" <> Enum.join(simple_fields, ", ") <> "]", %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "testFieldListing"})
    Log.trace("  Complex object fields: [" <> Enum.join(complex_fields, ", ") <> "]", %{:fileName => "Main.hx", :lineNumber => 80, :className => "Main", :methodName => "testFieldListing"})
    Log.trace("  Empty object fields: [" <> Enum.join(empty_fields, ", ") <> "]", %{:fileName => "Main.hx", :lineNumber => 81, :className => "Main", :methodName => "testFieldListing"})
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
    Log.trace("Object type checking:", %{:fileName => "Main.hx", :lineNumber => 100, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Object is object: " <> Std.string(obj_is_object), %{:fileName => "Main.hx", :lineNumber => 101, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  String is object: " <> Std.string(str_is_object), %{:fileName => "Main.hx", :lineNumber => 102, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Number is object: " <> Std.string(num_is_object), %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Array is object: " <> Std.string(arr_is_object), %{:fileName => "Main.hx", :lineNumber => 104, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Null is object: " <> Std.string(null_is_object), %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Function is object: " <> Std.string(fun_is_object), %{:fileName => "Main.hx", :lineNumber => 106, :className => "Main", :methodName => "testObjectChecking"})
    original = %{:a => 1, :b => %{:c => 2}}
    copied = original
    Log.trace("Object copying:", %{:fileName => "Main.hx", :lineNumber => 112, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Original a: " <> Reflect.field(original, "a"), %{:fileName => "Main.hx", :lineNumber => 113, :className => "Main", :methodName => "testObjectChecking"})
    Log.trace("  Copied a: " <> Reflect.field(copied, "a"), %{:fileName => "Main.hx", :lineNumber => 114, :className => "Main", :methodName => "testObjectChecking"})
  end
  defp test_comparison() do
    cmp_ints = Reflect.compare(5, 10)
    cmp_equal = Reflect.compare(42, 42)
    cmp_strings = Reflect.compare("apple", "banana")
    cmp_floats = Reflect.compare(3.14, 2.71)
    cmp_bools = Reflect.compare(true, false)
    cmp_arrays = Reflect.compare([1, 2], [1, 3])
    Log.trace("Value comparison:", %{:fileName => "Main.hx", :lineNumber => 126, :className => "Main", :methodName => "testComparison"})
    Log.trace("  5 vs 10: " <> cmp_ints, %{:fileName => "Main.hx", :lineNumber => 127, :className => "Main", :methodName => "testComparison"})
    Log.trace("  42 vs 42: " <> cmp_equal, %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "testComparison"})
    Log.trace("  \"apple\" vs \"banana\": " <> cmp_strings, %{:fileName => "Main.hx", :lineNumber => 129, :className => "Main", :methodName => "testComparison"})
    Log.trace("  3.14 vs 2.71: " <> cmp_floats, %{:fileName => "Main.hx", :lineNumber => 130, :className => "Main", :methodName => "testComparison"})
    Log.trace("  true vs false: " <> cmp_bools, %{:fileName => "Main.hx", :lineNumber => 131, :className => "Main", :methodName => "testComparison"})
    Log.trace("  [1,2] vs [1,3]: " <> cmp_arrays, %{:fileName => "Main.hx", :lineNumber => 132, :className => "Main", :methodName => "testComparison"})
  end
  defp test_enum_detection() do
    opt1 = {:Some, "value"}
    opt2 = :none
    res1 = {:Ok, 42}
    res2 = {:Error, "failed"}
    str = "not an enum"
    obj = %{:field => "value"}
    num = 123
    opt1_is_enum = Reflect.is_enum_value(opt)
    opt2_is_enum = Reflect.is_enum_value(opt)
    res1_is_enum = Reflect.is_enum_value(res)
    res2_is_enum = Reflect.is_enum_value(res)
    str_is_enum = Reflect.is_enum_value(str)
    obj_is_enum = Reflect.is_enum_value(obj)
    num_is_enum = Reflect.is_enum_value(num)
    Log.trace("Enum value detection:", %{:fileName => "Main.hx", :lineNumber => 154, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  Some(\"value\") is enum: " <> Std.string(opt1_is_enum), %{:fileName => "Main.hx", :lineNumber => 155, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  None is enum: " <> Std.string(opt2_is_enum), %{:fileName => "Main.hx", :lineNumber => 156, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  Ok(42) is enum: " <> Std.string(res1_is_enum), %{:fileName => "Main.hx", :lineNumber => 157, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  Error(\"failed\") is enum: " <> Std.string(res2_is_enum), %{:fileName => "Main.hx", :lineNumber => 158, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  String is enum: " <> Std.string(str_is_enum), %{:fileName => "Main.hx", :lineNumber => 159, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  Object is enum: " <> Std.string(obj_is_enum), %{:fileName => "Main.hx", :lineNumber => 160, :className => "Main", :methodName => "testEnumDetection"})
    Log.trace("  Number is enum: " <> Std.string(num_is_enum), %{:fileName => "Main.hx", :lineNumber => 161, :className => "Main", :methodName => "testEnumDetection"})
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
    Log.trace("Dynamic method calling:", %{:fileName => "Main.hx", :lineNumber => 188, :className => "Main", :methodName => "testMethodCalling"})
    Log.trace("  add(10, 20): " <> sum, %{:fileName => "Main.hx", :lineNumber => 189, :className => "Main", :methodName => "testMethodCalling"})
    Log.trace("  multiply(5, 6): " <> product, %{:fileName => "Main.hx", :lineNumber => 190, :className => "Main", :methodName => "testMethodCalling"})
    Log.trace("  greet(\"World\"): " <> greeting, %{:fileName => "Main.hx", :lineNumber => 191, :className => "Main", :methodName => "testMethodCalling"})
    Log.trace("  noArgs(): " <> no_args_result, %{:fileName => "Main.hx", :lineNumber => 192, :className => "Main", :methodName => "testMethodCalling"})
    calculator = %{:value => 100, :addTo => fn n -> n + 100 end, :multiplyBy => fn n -> n * 2 end}
    added = Reflect.call_method(calculator, Reflect.field(calculator, "addTo"), [50])
    multiplied = Reflect.call_method(calculator, Reflect.field(calculator, "multiplyBy"), [25])
    Log.trace("Object method calling:", %{:fileName => "Main.hx", :lineNumber => 208, :className => "Main", :methodName => "testMethodCalling"})
    Log.trace("  calculator.addTo(50): " <> added, %{:fileName => "Main.hx", :lineNumber => 209, :className => "Main", :methodName => "testMethodCalling"})
    Log.trace("  calculator.multiplyBy(25): " <> multiplied, %{:fileName => "Main.hx", :lineNumber => 210, :className => "Main", :methodName => "testMethodCalling"})
  end
end