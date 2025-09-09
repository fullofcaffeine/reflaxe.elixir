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
    name = Map.get(obj, String.to_atom("name"))
    age = Map.get(obj, String.to_atom("age"))
    missing = Map.get(obj, String.to_atom("nonexistent"))
    nested_name = Map.get(Map.get(nested, String.to_atom("user")), String.to_atom("name"))
    Log.trace("Field retrieval:", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  obj.name: " <> Kernel.to_string(name), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  obj.age: " <> Kernel.to_string(age), %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  obj.nonexistent: " <> Kernel.to_string(missing), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  nested.user.name: " <> Kernel.to_string(nested_name), %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testFieldOperations"})
    updated = Map.put(obj, String.to_atom("age"), 31)
    new_field = Map.put(obj, String.to_atom("city"), "New York")
    Log.trace("Field setting (immutable):", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  Updated age: " <> Kernel.to_string(Map.get(updated, String.to_atom("age"))), %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  New field city: " <> Kernel.to_string(Map.get(new_field, String.to_atom("city"))), %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testFieldOperations"})
    has_name = Map.has_key?(obj, String.to_atom("name"))
    has_city = Map.has_key?(obj, String.to_atom("city"))
    has_nested = Map.has_key?(nested, String.to_atom("user"))
    Log.trace("Field existence:", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  Has name: " <> Std.string(has_name), %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  Has city: " <> Std.string(has_city), %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  Has user: " <> Std.string(has_nested), %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "testFieldOperations"})
    deleted = Map.delete(obj, String.to_atom("age"))
    deleted_missing = Map.delete(obj, String.to_atom("nonexistent"))
    Log.trace("Field deletion:", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  After deleting age: " <> Std.string(Map.has_key?(deleted, String.to_atom("age"))), %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testFieldOperations"})
    Log.trace("  Delete nonexistent: " <> Kernel.to_string(Map.get(deleted_missing, String.to_atom("name"))), %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testFieldOperations"})
  end
  defp test_field_listing() do
    simple = %{:x => 10, :y => 20}
    complex = %{:id => 1, :name => "Test", :active => true, :data => [1, 2, 3], :meta => %{:created => "2024-01-01"}}
    empty = %{}
    simple_fields = Map.keys(simple)
    complex_fields = Map.keys(complex)
    empty_fields = Map.keys(empty)
    Log.trace("Field listing:", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "testFieldListing"})
    Log.trace("  Simple object fields: [" <> Enum.join(simple_fields, ", ") <> "]", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "testFieldListing"})
    Log.trace("  Complex object fields: [" <> Enum.join(complex_fields, ", ") <> "]", %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testFieldListing"})
    Log.trace("  Empty object fields: [" <> Enum.join(empty_fields, ", ") <> "]", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "testFieldListing"})
  end
  defp test_object_checking() do
    obj = %{:field => "value"}
    str = "string"
    num = 42
    arr = [1, 2, 3]
    nul = nil
    fun = fn x -> x * 2 end
    obj_is_object = is_map(obj)
    str_is_object = is_map(str)
    num_is_object = is_map(num)
    arr_is_object = is_map(arr)
    null_is_object = is_map(nul)
    fun_is_object = is_map(fun)
    Log.trace("Object type checking:", %{:file_name => "Main.hx", :line_number => 100, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Object is object: " <> Std.string(obj_is_object), %{:file_name => "Main.hx", :line_number => 101, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  String is object: " <> Std.string(str_is_object), %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Number is object: " <> Std.string(num_is_object), %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Array is object: " <> Std.string(arr_is_object), %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Null is object: " <> Std.string(null_is_object), %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Function is object: " <> Std.string(fun_is_object), %{:file_name => "Main.hx", :line_number => 106, :class_name => "Main", :method_name => "testObjectChecking"})
    original = %{:a => 1, :b => %{:c => 2}}
    copied = original
    Log.trace("Object copying:", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Original a: " <> Kernel.to_string(Map.get(original, String.to_atom("a"))), %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testObjectChecking"})
    Log.trace("  Copied a: " <> Kernel.to_string(Map.get(copied, String.to_atom("a"))), %{:file_name => "Main.hx", :line_number => 114, :class_name => "Main", :method_name => "testObjectChecking"})
  end
  defp test_comparison() do
    cmp_ints = cond do
  5 < 10 ->
    -1
  5 > 10 ->
    1
  true ->
    0
end
    cmp_equal = cond do
  42 < 42 ->
    -1
  42 > 42 ->
    1
  true ->
    0
end
    cmp_strings = cond do
  "apple" < "banana" ->
    -1
  "apple" > "banana" ->
    1
  true ->
    0
end
    cmp_floats = cond do
  3.14 < 2.71 ->
    -1
  3.14 > 2.71 ->
    1
  true ->
    0
end
    cmp_bools = cond do
  true < false ->
    -1
  true > false ->
    1
  true ->
    0
end
    cmp_arrays = cond do
  [1, 2] < [1, 3] ->
    -1
  [1, 2] > [1, 3] ->
    1
  true ->
    0
end
    Log.trace("Value comparison:", %{:file_name => "Main.hx", :line_number => 126, :class_name => "Main", :method_name => "testComparison"})
    Log.trace("  5 vs 10: " <> Kernel.to_string(cmp_ints), %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testComparison"})
    Log.trace("  42 vs 42: " <> Kernel.to_string(cmp_equal), %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testComparison"})
    Log.trace("  \"apple\" vs \"banana\": " <> Kernel.to_string(cmp_strings), %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testComparison"})
    Log.trace("  3.14 vs 2.71: " <> Kernel.to_string(cmp_floats), %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "testComparison"})
    Log.trace("  true vs false: " <> Kernel.to_string(cmp_bools), %{:file_name => "Main.hx", :line_number => 131, :class_name => "Main", :method_name => "testComparison"})
    Log.trace("  [1,2] vs [1,3]: " <> Kernel.to_string(cmp_arrays), %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "testComparison"})
  end
  defp test_enum_detection() do
    opt1 = {:Some, "value"}
    opt2 = {1}
    res1 = {:Ok, 42}
    res2 = {:Error, "failed"}
    str = "not an enum"
    obj = %{:field => "value"}
    num = 123
    opt1_is_enum = is_tuple(opt1) and is_atom(elem(opt1, 0))
    opt2_is_enum = is_tuple(opt2) and is_atom(elem(opt2, 0))
    res1_is_enum = is_tuple(res1) and is_atom(elem(res1, 0))
    res2_is_enum = is_tuple(res2) and is_atom(elem(res2, 0))
    str_is_enum = is_tuple(str) and is_atom(elem(str, 0))
    obj_is_enum = is_tuple(obj) and is_atom(elem(obj, 0))
    num_is_enum = is_tuple(num) and is_atom(elem(num, 0))
    Log.trace("Enum value detection:", %{:file_name => "Main.hx", :line_number => 154, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  Some(\"value\") is enum: " <> Std.string(opt1_is_enum), %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  None is enum: " <> Std.string(opt2_is_enum), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  Ok(42) is enum: " <> Std.string(res1_is_enum), %{:file_name => "Main.hx", :line_number => 157, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  Error(\"failed\") is enum: " <> Std.string(res2_is_enum), %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  String is enum: " <> Std.string(str_is_enum), %{:file_name => "Main.hx", :line_number => 159, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  Object is enum: " <> Std.string(obj_is_enum), %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "testEnumDetection"})
    Log.trace("  Number is enum: " <> Std.string(num_is_enum), %{:file_name => "Main.hx", :line_number => 161, :class_name => "Main", :method_name => "testEnumDetection"})
  end
  defp test_method_calling() do
    add = fn a, b -> a + b end
    multiply = fn x, y -> x * y end
    greet = fn name -> "Hello, " <> name <> "!" end
    no_args = fn -> "No arguments" end
    sum = apply(add, [10, 20])
    product = apply(multiply, [5, 6])
    greeting = apply(greet, ["World"])
    no_args_result = apply(no_args, [])
    Log.trace("Dynamic method calling:", %{:file_name => "Main.hx", :line_number => 188, :class_name => "Main", :method_name => "testMethodCalling"})
    Log.trace("  add(10, 20): " <> sum, %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "testMethodCalling"})
    Log.trace("  multiply(5, 6): " <> product, %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "testMethodCalling"})
    Log.trace("  greet(\"World\"): " <> greeting, %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "testMethodCalling"})
    Log.trace("  noArgs(): " <> no_args_result, %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "testMethodCalling"})
    calculator = %{:value => 100, :add_to => fn n -> n + 100 end, :multiply_by => fn n -> n * 2 end}
    added = apply(Map.get(calculator, String.to_atom("addTo")), [50])
    multiplied = apply(Map.get(calculator, String.to_atom("multiplyBy")), [25])
    Log.trace("Object method calling:", %{:file_name => "Main.hx", :line_number => 208, :class_name => "Main", :method_name => "testMethodCalling"})
    Log.trace("  calculator.addTo(50): " <> added, %{:file_name => "Main.hx", :line_number => 209, :class_name => "Main", :method_name => "testMethodCalling"})
    Log.trace("  calculator.multiplyBy(25): " <> multiplied, %{:file_name => "Main.hx", :line_number => 210, :class_name => "Main", :method_name => "testMethodCalling"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()