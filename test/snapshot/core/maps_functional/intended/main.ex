defmodule Main do
  defp main() do
    numbers = g = %{}
Map.put(g, "one", 1)
Map.put(g, "two", 2)
Map.put(g, "three", 3)
Map.put(g, "four", 4)
Map.put(g, "five", 5)
g
    count = MapTools.size(numbers)
    Log.trace("Map size: " + count, %{:fileName => "Main.hx", :lineNumber => 13, :className => "Main", :methodName => "main"})
    not_empty = MapTools.is_empty(numbers)
    Log.trace("Numbers empty check: " + Std.string(not_empty), %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "main"})
    empty = %{}
    is_empty_result = MapTools.is_empty(empty)
    Log.trace("Empty map check: " + Std.string(is_empty_result), %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "main"})
    has_even = MapTools.any(numbers, fn k, v -> v rem 2 == 0 end)
    Log.trace("Has even values: " + Std.string(has_even), %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    all_positive = MapTools.all(numbers, fn k, v -> v > 0 end)
    Log.trace("All positive: " + Std.string(all_positive), %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "main"})
    sum = MapTools.reduce(numbers, 0, fn acc, k, v -> acc + v end)
    Log.trace("Sum of values: " + sum, %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "main"})
    found = MapTools.find(numbers, fn k, v -> v > 3 end)
    if (found != nil) do
      Log.trace("Found item with value > 3: " + found.key + " = " + found.value, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "main"})
    end
    key_array = MapTools.keys(numbers)
    Log.trace("Keys array length: " + key_array.length, %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "main"})
    value_array = MapTools.values(numbers)
    Log.trace("Values array length: " + value_array.length, %{:fileName => "Main.hx", :lineNumber => 48, :className => "Main", :methodName => "main"})
    pair_array = MapTools.to_array(numbers)
    Log.trace("Pairs array length: " + pair_array.length, %{:fileName => "Main.hx", :lineNumber => 52, :className => "Main", :methodName => "main"})
  end
end