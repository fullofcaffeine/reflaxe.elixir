defmodule Main do
  def main() do
    _float_str = Reflaxe.Elixir.HaxeFloat.to_string(3.14)
    _null_str = Reflaxe.Elixir.HaxeFloat.to_string(nil)
    _array_str = Reflaxe.Elixir.HaxeFloat.to_string([1, 2, 3])
    _parsed1 = (case Integer.parse("123") do
      {num, _} -> num
      :error -> nil
    end)
    _parsed2 = (case Integer.parse("456abc") do
      {num, _} -> num
      :error -> nil
    end)
    _parsed3 = (case Integer.parse("not a number") do
      {num, _} -> num
      :error -> nil
    end)
    _ = Reflaxe.Elixir.HaxeFloat.parse("3.14")
    _ = Reflaxe.Elixir.HaxeFloat.parse("2.71828")
    _ = Reflaxe.Elixir.HaxeFloat.parse("invalid")
    _is_string = is_binary("hello")
    _is_int = Std.is(42, Int)
    _is_float = Reflaxe.Elixir.HaxeFloat.is_haxe_float(3.14)
    _is_bool = Std.is(true, Bool)
    _is_array = is_list([1, 2, 3])
    _check_string = Std.is("world", String)
    _check_int = Std.is(100, Int)
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
    _int_max = (case Integer.parse("2147483647") do
      {num, _} -> num
      :error -> nil
    end)
    _int_min = (case Integer.parse("-2147483648") do
      {num, _} -> num
      :error -> nil
    end)
    _float_inf = Reflaxe.Elixir.HaxeFloat.parse("Infinity")
    float_neg_inf = Reflaxe.Elixir.HaxeFloat.parse("-Infinity")
    float_neg_inf
  end
end
