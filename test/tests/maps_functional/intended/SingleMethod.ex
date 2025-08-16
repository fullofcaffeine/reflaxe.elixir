defmodule SingleMethod do
  @moduledoc """
  SingleMethod module generated from Haxe
  
  
 * Test MapTools methods that work (don't create new Maps)
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    _g = Haxe.Ds.StringMap.new()
    _g.set("one", 1)
    _g.set("two", 2)
    _g.set("three", 3)
    _g.set("four", 4)
    _g.set("five", 5)
    count = Map.size(_g)
    Log.trace("Map size: " <> Integer.to_string(count), %{"fileName" => "SingleMethod.hx", "lineNumber" => 12, "className" => "SingleMethod", "methodName" => "main"})
    not_empty = Map.equal?(_g, %{})
    Log.trace("Numbers empty check: " <> Std.string(not_empty), %{"fileName" => "SingleMethod.hx", "lineNumber" => 16, "className" => "SingleMethod", "methodName" => "main"})
    empty = Haxe.Ds.StringMap.new()
    is_empty_result = Map.equal?(empty, %{})
    Log.trace("Empty map check: " <> Std.string(is_empty_result), %{"fileName" => "SingleMethod.hx", "lineNumber" => 21, "className" => "SingleMethod", "methodName" => "main"})
    has_even = Enum.any?(Map.to_list(_g), fn {k, v} -> v rem 2 == 0 end)
    Log.trace("Has even values: " <> Std.string(has_even), %{"fileName" => "SingleMethod.hx", "lineNumber" => 25, "className" => "SingleMethod", "methodName" => "main"})
    all_positive = Enum.all?(Map.to_list(_g), fn {k, v} -> v > 0 end)
    Log.trace("All positive: " <> Std.string(all_positive), %{"fileName" => "SingleMethod.hx", "lineNumber" => 29, "className" => "SingleMethod", "methodName" => "main"})
    sum = Map.fold(_g, 0, fn k, v, acc -> acc + v end)
    Log.trace("Sum of values: " <> Integer.to_string(sum), %{"fileName" => "SingleMethod.hx", "lineNumber" => 33, "className" => "SingleMethod", "methodName" => "main"})
    found = Enum.find(Map.to_list(_g), fn {k, v} -> v > 3 end)
    if (found != nil), do: Log.trace("Found item with value > 3: " <> found.key <> " = " <> Integer.to_string(found.value), %{"fileName" => "SingleMethod.hx", "lineNumber" => 38, "className" => "SingleMethod", "methodName" => "main"}), else: nil
    key_array = Map.keys(_g)
    Log.trace("Keys array length: " <> Integer.to_string(length(key_array)), %{"fileName" => "SingleMethod.hx", "lineNumber" => 43, "className" => "SingleMethod", "methodName" => "main"})
    value_array = Map.values(_g)
    Log.trace("Values array length: " <> Integer.to_string(length(value_array)), %{"fileName" => "SingleMethod.hx", "lineNumber" => 47, "className" => "SingleMethod", "methodName" => "main"})
    pair_array = Map.to_list(_g)
    Log.trace("Pairs array length: " <> Integer.to_string(length(pair_array)), %{"fileName" => "SingleMethod.hx", "lineNumber" => 51, "className" => "SingleMethod", "methodName" => "main"})
  end

end
