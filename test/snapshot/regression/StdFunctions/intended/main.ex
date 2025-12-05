defmodule Main do
  def main() do
    _ = test_string_conversion()
    _ = test_parsing()
    _ = test_type_checking()
    _ = test_random_and_int()
  end
  defp test_string_conversion() do
    int_str = "42"
    float_str = inspect(3.14)
    bool_str = "true"
    null_str = inspect(nil)
    obj = %{:name => "test", :value => 123}
    obj_str = inspect(obj)
    arr = [1, 2, 3]
    arr_str = inspect(arr)
    option = {:some, "value"}
    option_str = inspect(option)
    nil
  end
  defp test_parsing() do
    valid_int = String.to_integer("42")
    negative_int = String.to_integer("-123")
    invalid_int = String.to_integer("abc")
    partial_int = String.to_integer("42abc")
    empty_int = String.to_integer("")
    valid_float = String.to_float("3.14")
    negative_float = String.to_float("-2.5")
    int_as_float = String.to_float("42")
    invalid_float = String.to_float("xyz")
    partial_float = String.to_float("3.14xyz")
    nil
  end
  defp test_type_checking() do
    str = "hello"
    num = 42
    float = 3.14
    bool = true
    arr = [1, 2, 3]
    _ = nil
    obj_field = "value"
    str_is_string = str_is_string.(str)
    arr_is_array = str_is_string.(arr)
    nil
  end
  defp test_random_and_int() do
    _ = MyApp.Std.random()
    _ = MyApp.Std.random()
    _ = MyApp.Std.random()
    _ = 3
    _ = 3
    _ = -2
    _ = -2
    _ = 0
    nil
  end
end
