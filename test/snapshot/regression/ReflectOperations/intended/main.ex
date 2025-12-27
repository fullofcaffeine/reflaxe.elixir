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
    updated = Map.put(obj, "age", 31)
    new_field = Map.put(obj, "city", "New York")
    has_name = Map.has_key?(obj, "name")
    has_city = Map.has_key?(obj, "city")
    has_nested = Map.has_key?(nested, "user")
    deleted = Reflect.delete_field(obj, "age")
    deleted_missing = Reflect.delete_field(obj, "nonexistent")
    nil
  end
  defp test_field_listing() do
    simple = %{:x => 10, :y => 20}
    complex = %{:id => 1, :name => "Test", :active => true, :data => [1, 2, 3], :meta => %{:created => "2024-01-01"}}
    empty = %{}
    simple_fields = Reflect.fields(simple)
    complex_fields = Reflect.fields(complex)
    empty_fields = Reflect.fields(empty)
    nil
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
    copied_a = 1
    copied_b_c = 2
    nil
  end
  defp test_comparison() do
    cmp_ints = Reflect.compare(5, 10)
    cmp_equal = Reflect.compare(42, 42)
    cmp_strings = Reflect.compare("apple", "banana")
    cmp_floats = Reflect.compare(3.14, 2.71)
    cmp_bools = Reflect.compare(true, false)
    cmp_arrays = Reflect.compare([1, 2], [1, 3])
    nil
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
    nil
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
    calculator = %{:value => 100, :add_to => fn n -> n + 100 end, :multiply_by => fn n -> n * 2 end}
    added = Reflect.call_method(calculator, Map.get(calculator, "addTo"), [50])
    multiplied = Reflect.call_method(calculator, Map.get(calculator, "multiplyBy"), [25])
    nil
  end
end
