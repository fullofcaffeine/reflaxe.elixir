defmodule Main do
  def main() do
    numbers = %{"one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5}
    count = MapTools.size(numbers)
    Log.trace("Map size: #{count}", %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "main"})
    not_empty = MapTools.is_empty(numbers)
    Log.trace("Numbers empty check: #{inspect(not_empty)}", %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "main"})
    empty = %{}
    is_empty_result = MapTools.is_empty(empty)
    Log.trace("Empty map check: #{inspect(is_empty_result)}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "main"})
    has_even = MapTools.any(numbers, fn _k, v -> rem(v, 2) == 0 end)
    Log.trace("Has even values: #{inspect(has_even)}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
    all_positive = MapTools.all(numbers, fn _k, v -> v > 0 end)
    Log.trace("All positive: #{inspect(all_positive)}", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "main"})
    sum = MapTools.reduce(numbers, 0, fn acc, _k, v -> acc + v end)
    Log.trace("Sum of values: #{sum}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "main"})
    found = MapTools.find(numbers, fn _k, v -> v > 3 end)
    if found != nil do
      Log.trace("Found item with value > 3: #{found.key} = #{found.value}", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "main"})
    end
    key_array = MapTools.keys(numbers)
    Log.trace("Keys array length: #{length(key_array)}", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
    value_array = MapTools.values(numbers)
    Log.trace("Values array length: #{length(value_array)}", %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "main"})
    pair_array = MapTools.to_array(numbers)
    Log.trace("Pairs array length: #{length(pair_array)}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
  end
end