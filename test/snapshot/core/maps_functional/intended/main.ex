defmodule Main do
  def main() do
    g = %{}
    g = Map.put(g, "one", 1)
    g = Map.put(g, "two", 2)
    g = Map.put(g, "three", 3)
    g = Map.put(g, "four", 4)
    g = Map.put(g, "five", 5)
    numbers = g
    count = MapTools.size(numbers)
    Log.trace("Map size: " <> Kernel.to_string(count), %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})
    not_empty = MapTools.is_empty(numbers)
    Log.trace("Numbers empty check: " <> Std.string(not_empty), %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "main"})
    empty = %{}
    is_empty_result = MapTools.is_empty(empty)
    Log.trace("Empty map check: " <> Std.string(is_empty_result), %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "main"})
    has_even = MapTools.any(numbers, fn _k, v -> rem(v, 2) == 0 end)
    Log.trace("Has even values: " <> Std.string(has_even), %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    all_positive = MapTools.all(numbers, fn _k, v -> v > 0 end)
    Log.trace("All positive: " <> Std.string(all_positive), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "main"})
    sum = MapTools.reduce(numbers, 0, fn acc, _k, v -> acc + v end)
    Log.trace("Sum of values: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "main"})
    found = MapTools.find(numbers, fn _k, v -> v > 3 end)
    if (found != nil) do
      Log.trace("Found item with value > 3: " <> found.key <> " = " <> Kernel.to_string(found.value), %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "main"})
    end
    key_array = MapTools.keys(numbers)
    Log.trace("Keys array length: " <> Kernel.to_string(length(key_array)), %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "main"})
    value_array = MapTools.values(numbers)
    Log.trace("Values array length: " <> Kernel.to_string(length(value_array)), %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "main"})
    pair_array = MapTools.to_array(numbers)
    Log.trace("Pairs array length: " <> Kernel.to_string(length(pair_array)), %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("map_tools.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()