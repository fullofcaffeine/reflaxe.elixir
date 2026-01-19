defmodule Main do
  def main() do
    _ = test_simple_map_iteration()
    _ = test_key_only_iteration()
    _ = test_value_only_iteration()
    _ = test_map_comprehension()
    _ = test_nested_map_iteration()
    _ = test_map_iteration_with_filter()
    _ = test_map_iteration_with_accumulation()
  end
  defp test_simple_map_iteration() do
    colors = %{}
    colors = Map.put(colors, "red", "#FF0000")
    _ = colors
  end
  defp test_key_only_iteration() do
    inventory = %{}
    inventory = Map.put(inventory, "apples", 10)
    _ = inventory
  end
  defp test_value_only_iteration() do
    scores = %{}
    scores = Map.put(scores, "Alice", 95)
    _ = scores
  end
  defp test_map_comprehension() do
    prices = %{}
    prices = Map.put(prices, "apple", 1.5)
    _ = prices
  end
  defp test_nested_map_iteration() do
    engineering = %{}
    engineering = Map.put(engineering, "Alice", 5)
    _ = engineering
  end
  defp test_map_iteration_with_filter() do
    ages = %{}
    ages = Map.put(ages, "Alice", 25)
    _ = ages
  end
  defp test_map_iteration_with_accumulation() do
    products = %{}
    products = Map.put(products, "laptop", 999.99)
    _ = products
  end
end
