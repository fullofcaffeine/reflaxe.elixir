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
    _updated = Map.put(obj, "age", 31)
    _new_field = Map.put(obj, "city", "New York")
    _has_name = Map.has_key?(obj, "name")
    _has_city = Map.has_key?(obj, "city")
    _has_nested = Map.has_key?(nested, "user")
    _deleted = Reflect.delete_field(obj, "age")
    _deleted_missing = Reflect.delete_field(obj, "nonexistent")
    nil
  end
  defp test_field_listing() do
    simple = %{:x => 10, :y => 20}
    complex = %{:id => 1, :name => "Test", :active => true, :data => [1, 2, 3], :meta => %{:created => "2024-01-01"}}
    empty = %{}
    _simple_fields = Reflect.fields(simple)
    _complex_fields = Reflect.fields(complex)
    _empty_fields = Reflect.fields(empty)
    nil
  end
  defp test_object_checking() do
    obj = %{:field => "value"}
    str = "string"
    num = 42
    arr = [1, 2, 3]
    nul = nil
    fun = fn x -> x * 2 end
    _obj_is_object = Reflect.is_object(obj)
    _str_is_object = Reflect.is_object(str)
    _num_is_object = Reflect.is_object(num)
    _arr_is_object = Reflect.is_object(arr)
    _null_is_object = Reflect.is_object(nul)
    _fun_is_object = Reflect.is_object(fun)
    nil
  end
  defp test_comparison() do
    _cmp_ints = Reflect.compare(5, 10)
    _cmp_equal = Reflect.compare(42, 42)
    _cmp_strings = Reflect.compare("apple", "banana")
    _cmp_floats = Reflect.compare(3.14, 2.71)
    _cmp_bools = Reflect.compare(true, false)
    _cmp_arrays = Reflect.compare([1, 2], [1, 3])
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
    _opt1_is_enum = Reflect.is_enum_value(opt1)
    _opt2_is_enum = Reflect.is_enum_value(opt2)
    _res1_is_enum = Reflect.is_enum_value(res1)
    _res2_is_enum = Reflect.is_enum_value(res2)
    _str_is_enum = Reflect.is_enum_value(str)
    _obj_is_enum = Reflect.is_enum_value(obj)
    _num_is_enum = Reflect.is_enum_value(num)
    nil
  end
  defp test_method_calling() do
    add = fn a, b -> a + b end
    multiply = fn x, y -> x * y end
    greet = fn name -> "Hello, " <> name <> "!" end
    no_args = fn -> "No arguments" end
    _sum = Reflect.call_method(nil, add, [10, 20])
    _product = Reflect.call_method(nil, multiply, [5, 6])
    _greeting = Reflect.call_method(nil, greet, ["World"])
    _no_args_result = Reflect.call_method(nil, no_args, [])
    calculator = %{:value => 100, :add_to => fn n -> n + 100 end, :multiply_by => fn n -> n * 2 end}
    _added = Reflect.call_method(calculator, Map.get(calculator, "addTo"), [50])
    _multiplied = Reflect.call_method(calculator, Map.get(calculator, "multiplyBy"), [25])
    nil
  end
end
