defmodule Main do
  def main() do
    numbers = %{"one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5}
    _count = MapTools.size(numbers)
    _not_empty = MapTools.is_empty(numbers)
    empty = %{}
    _is_empty_result = MapTools.is_empty(empty)
    _has_even = MapTools.any(numbers, fn _, v -> rem(v, 2) == 0 end)
    _all_positive = MapTools.all(numbers, fn _, v -> v > 0 end)
    _sum = MapTools.reduce(numbers, 0, fn acc, _, v -> acc + v end)
    found = MapTools.find(numbers, fn _, v -> v > 3 end)
    if (not Kernel.is_nil(found)), do: nil
    _key_array = MapTools.keys(numbers)
    _value_array = MapTools.values(numbers)
    _pair_array = MapTools.to_array(numbers)
    nil
  end
end
