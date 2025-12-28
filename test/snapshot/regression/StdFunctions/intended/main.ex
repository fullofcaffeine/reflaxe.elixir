defmodule Main do
  def main() do
    _ = test_string_conversion()
    _ = test_parsing()
    _ = test_type_checking()
    _ = test_random_and_int()
  end
  defp test_string_conversion() do
    _float_str = inspect(3.14)
    _null_str = inspect(nil)
    obj = %{:name => "test", :value => 123}
    _obj_str = inspect(obj)
    arr = [1, 2, 3]
    _arr_str = inspect(arr)
    option = {:some, "value"}
    _option_str = inspect(option)
    nil
  end
  defp test_parsing() do
    _valid_int = ((case Integer.parse("42") do
  {num, _} -> num
  :error -> nil
end))
    _negative_int = ((case Integer.parse("-123") do
  {num, _} -> num
  :error -> nil
end))
    _invalid_int = ((case Integer.parse("abc") do
  {num, _} -> num
  :error -> nil
end))
    _partial_int = ((case Integer.parse("42abc") do
  {num, _} -> num
  :error -> nil
end))
    _empty_int = ((case Integer.parse("") do
  {num, _} -> num
  :error -> nil
end))
    _valid_float = ((case Float.parse("3.14") do
  {num, _} -> num
  :error -> nil
end))
    _negative_float = ((case Float.parse("-2.5") do
  {num, _} -> num
  :error -> nil
end))
    _int_as_float = ((case Float.parse("42") do
  {num, _} -> num
  :error -> nil
end))
    _invalid_float = ((case Float.parse("xyz") do
  {num, _} -> num
  :error -> nil
end))
    _partial_float = ((case Float.parse("3.14xyz") do
  {num, _} -> num
  :error -> nil
end))
    nil
  end
  defp test_type_checking() do
    str = "hello"
    arr = [1, 2, 3]
    _str_is_string = is_binary(str)
    _arr_is_array = is_list(arr)
    nil
  end
  defp test_random_and_int() do
    _rand1 = ((case 100 do
  std_random_max when std_random_max <= 0 -> 0
  std_random_max -> (:rand.uniform(std_random_max) - 1)
end))
    _rand2 = ((case 100 do
  std_random_max when std_random_max <= 0 -> 0
  std_random_max -> (:rand.uniform(std_random_max) - 1)
end))
    _rand3 = ((case 100 do
  std_random_max when std_random_max <= 0 -> 0
  std_random_max -> (:rand.uniform(std_random_max) - 1)
end))
    _ = 3
    _ = 3
    _ = -2
    _ = -2
    _ = 0
    nil
  end
end
