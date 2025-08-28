defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * MapTools functional methods test case
     * Tests MapTools static extension methods for proper compilation to idiomatic Elixir
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    g_array = StringMap.new()

    g_array = Map.put(g_array, "one", 1)

    g_array = Map.put(g_array, "two", 2)

    g_array = Map.put(g_array, "three", 3)

    g_array = Map.put(g_array, "four", 4)

    g_array = Map.put(g_array, "five", 5)

    count = Map.size(g_array)

    Log.trace("Map size: " <> to_string(count), %{"fileName" => "Main.hx", "lineNumber" => 13, "className" => "Main", "methodName" => "main"})

    not_empty = MapTools.is_empty(g_array)

    Log.trace("Numbers empty check: " <> Std.string(not_empty), %{"fileName" => "Main.hx", "lineNumber" => 17, "className" => "Main", "methodName" => "main"})

    empty = StringMap.new()

    is_empty_result = MapTools.is_empty(empty)

    Log.trace("Empty map check: " <> Std.string(is_empty_result), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "main"})

    has_even = Enum.any?(Map.to_list(g_array), fn {k, v} -> (rem(v, 2) == 0) end)

    Log.trace("Has even values: " <> Std.string(has_even), %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "main"})

    all_positive = Enum.all?(Map.to_list(g_array), fn {k, v} -> (v > 0) end)

    Log.trace("All positive: " <> Std.string(all_positive), %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "main"})

    sum = Map.fold(g_array, 0, fn k, v, acc -> (acc + v) end)

    Log.trace("Sum of values: " <> to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 34, "className" => "Main", "methodName" => "main"})

    found = Enum.find(Map.to_list(g_array), fn {k, v} -> (v > 3) end)

    if ((found != nil)), do: Log.trace("Found item with value > 3: " <> found.key <> " = " <> to_string(found.value), %{"fileName" => "Main.hx", "lineNumber" => 39, "className" => "Main", "methodName" => "main"}), else: nil

    key_array = Map.keys(g_array)

    Log.trace("Keys array length: " <> to_string(key_array.length), %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "main"})

    value_array = Map.values(g_array)

    Log.trace("Values array length: " <> to_string(value_array.length), %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "main"})

    pair_array = MapTools.to_array(g_array)

    Log.trace("Pairs array length: " <> to_string(pair_array.length), %{"fileName" => "Main.hx", "lineNumber" => 52, "className" => "Main", "methodName" => "main"})
  end

end
