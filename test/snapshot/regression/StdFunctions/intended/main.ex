defmodule Main do
  def main() do
    test_string_conversion()
    test_parsing()
    test_type_checking()
    test_random_and_int()
  end
  defp test_string_conversion() do
    _float_str = Reflaxe.Elixir.HaxeFloat.to_string(3.14)
    _null_str = Reflaxe.Elixir.HaxeFloat.to_string(nil)
    obj = %{name: "test", value: 123}
    _obj_str = Reflaxe.Elixir.HaxeFloat.to_string(obj)
    arr = [1, 2, 3]
    _arr_str = Reflaxe.Elixir.HaxeFloat.to_string(arr)
    option = {:some, "value"}
    option_str = Reflaxe.Elixir.HaxeFloat.enum_to_string(Option, option)
    if (option_str != "Some(value)") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "local enum formatting failed: " <> option_str]
    end
    nil
  end
  defp test_parsing() do
    _valid_int = Reflaxe.Elixir.HaxeInt.parse("42")
    _negative_int = Reflaxe.Elixir.HaxeInt.parse("-123")
    _invalid_int = Reflaxe.Elixir.HaxeInt.parse("abc")
    _partial_int = Reflaxe.Elixir.HaxeInt.parse("42abc")
    _empty_int = Reflaxe.Elixir.HaxeInt.parse("")
    _valid_float = Reflaxe.Elixir.HaxeFloat.parse("3.14")
    _negative_float = Reflaxe.Elixir.HaxeFloat.parse("-2.5")
    _int_as_float = Reflaxe.Elixir.HaxeFloat.parse("42")
    _invalid_float = Reflaxe.Elixir.HaxeFloat.parse("xyz")
    _partial_float = Reflaxe.Elixir.HaxeFloat.parse("3.14xyz")
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
    _rand1 = (case 100 do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)
    _rand2 = (case 100 do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)
    _rand3 = (case 100 do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)
    nil
  end
end
