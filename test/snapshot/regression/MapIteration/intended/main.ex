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
    _ = apply(Map.get(colors, :__reflaxe_class__) || Map.get(colors, :__struct__), :set, [colors, "red", "#FF0000"])
    _ = apply(Map.get(colors, :__reflaxe_class__) || Map.get(colors, :__struct__), :set, [colors, "green", "#00FF00"])
    _ = apply(Map.get(colors, :__reflaxe_class__) || Map.get(colors, :__struct__), :set, [colors, "blue", "#0000FF"])
    g = apply(Map.get(colors, :__reflaxe_class__) || Map.get(colors, :__struct__), :key_value_iterator, [colors])
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if (g.has_next.()) do
      name = g.next.().key
      hex = g.next.().value
      nil
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
  end
  defp test_key_only_iteration() do
    inventory = %{}
    _ = apply(Map.get(inventory, :__reflaxe_class__) || Map.get(inventory, :__struct__), :set, [inventory, "apples", 10])
    _ = apply(Map.get(inventory, :__reflaxe_class__) || Map.get(inventory, :__struct__), :set, [inventory, "oranges", 5])
    _ = apply(Map.get(inventory, :__reflaxe_class__) || Map.get(inventory, :__struct__), :set, [inventory, "bananas", 8])
    keys = []
    g = apply(Map.get(inventory, :__reflaxe_class__) || Map.get(inventory, :__struct__), :key_value_iterator, [inventory])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {keys}, fn _, {acc_keys} ->
      try do
        if (g.has_next.()) do
          item = g.next.().key
          _ = g.next.().value
          acc_keys = acc_keys ++ [item]
          {:cont, {acc_keys}}
        else
          {:halt, {acc_keys}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_keys}}
        :throw, :continue ->
          {:cont, {acc_keys}}
      end
    end)
    nil
  end
  defp test_value_only_iteration() do
    scores = %{}
    _ = apply(Map.get(scores, :__reflaxe_class__) || Map.get(scores, :__struct__), :set, [scores, "Alice", 95])
    _ = apply(Map.get(scores, :__reflaxe_class__) || Map.get(scores, :__struct__), :set, [scores, "Bob", 87])
    _ = apply(Map.get(scores, :__reflaxe_class__) || Map.get(scores, :__struct__), :set, [scores, "Charlie", 92])
    total = 0
    g = apply(Map.get(scores, :__reflaxe_class__) || Map.get(scores, :__struct__), :key_value_iterator, [scores])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total}, fn _, {acc_total} ->
      try do
        if (g.has_next.()) do
          _ = g.next.().key
          score = g.next.().value
          acc_total = acc_total + score
          {:cont, {acc_total}}
        else
          {:halt, {acc_total}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_total}}
        :throw, :continue ->
          {:cont, {acc_total}}
      end
    end)
    nil
  end
  defp test_map_comprehension() do
    prices = %{}
    _ = apply(Map.get(prices, :__reflaxe_class__) || Map.get(prices, :__struct__), :set, [prices, "apple", 1.5])
    _ = apply(Map.get(prices, :__reflaxe_class__) || Map.get(prices, :__struct__), :set, [prices, "orange", 2])
    _ = apply(Map.get(prices, :__reflaxe_class__) || Map.get(prices, :__struct__), :set, [prices, "banana", 0.75])
    g_value = apply(Map.get(prices, :__reflaxe_class__) || Map.get(prices, :__struct__), :key_value_iterator, [prices])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[]}, fn _, {acc__g} ->
      try do
        if (g_value.has_next.()) do
          item = g_value.next.().key
          price = g_value.next.().value
          acc__g = acc__g ++ ["" <> item <> ": $" <> Kernel.to_string(price * 0.9)]
          {:cont, {acc__g}}
        else
          {:halt, {acc__g}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc__g}}
        :throw, :continue ->
          {:cont, {acc__g}}
      end
    end)
    _discounted = []
    nil
  end
  defp test_nested_map_iteration() do
    departments = %{}
    engineering = %{}
    _ = apply(Map.get(engineering, :__reflaxe_class__) || Map.get(engineering, :__struct__), :set, [engineering, "Alice", 5])
    _ = apply(Map.get(engineering, :__reflaxe_class__) || Map.get(engineering, :__struct__), :set, [engineering, "Bob", 3])
    _ = apply(Map.get(departments, :__reflaxe_class__) || Map.get(departments, :__struct__), :set, [departments, "Engineering", engineering])
    sales = %{}
    _ = apply(Map.get(sales, :__reflaxe_class__) || Map.get(sales, :__struct__), :set, [sales, "Charlie", 7])
    _ = apply(Map.get(sales, :__reflaxe_class__) || Map.get(sales, :__struct__), :set, [sales, "Diana", 4])
    _ = apply(Map.get(departments, :__reflaxe_class__) || Map.get(departments, :__struct__), :set, [departments, "Sales", sales])
    g = apply(Map.get(departments, :__reflaxe_class__) || Map.get(departments, :__struct__), :key_value_iterator, [departments])
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if (g.has_next.()) do
      dept = g.next.().key
      employees = g.next.().value
      g = apply(Map.get(employees, :__reflaxe_class__) || Map.get(employees, :__struct__), :key_value_iterator, [employees])
      _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
        try do
          if (g.has_next.()) do
            name = g.next.().key
            years = g.next.().value
            nil
            {:cont, acc}
          else
            {:halt, acc}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, acc}
          :throw, :continue ->
            {:cont, acc}
        end
      end)
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
  end
  defp test_map_iteration_with_filter() do
    ages = %{}
    _ = apply(Map.get(ages, :__reflaxe_class__) || Map.get(ages, :__struct__), :set, [ages, "Alice", 25])
    _ = apply(Map.get(ages, :__reflaxe_class__) || Map.get(ages, :__struct__), :set, [ages, "Bob", 17])
    _ = apply(Map.get(ages, :__reflaxe_class__) || Map.get(ages, :__struct__), :set, [ages, "Charlie", 30])
    _ = apply(Map.get(ages, :__reflaxe_class__) || Map.get(ages, :__struct__), :set, [ages, "Diana", 16])
    adults = []
    g = apply(Map.get(ages, :__reflaxe_class__) || Map.get(ages, :__struct__), :key_value_iterator, [ages])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {adults}, fn _, {acc_adults} ->
      try do
        if (g.has_next.()) do
          name = g.next.().key
          age = g.next.().value
          acc_adults = if (age >= 18), do: acc_adults ++ [name], else: acc_adults
          {:cont, {acc_adults}}
        else
          {:halt, {acc_adults}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_adults}}
        :throw, :continue ->
          {:cont, {acc_adults}}
      end
    end)
    nil
  end
  defp test_map_iteration_with_accumulation() do
    products = %{}
    _ = apply(Map.get(products, :__reflaxe_class__) || Map.get(products, :__struct__), :set, [products, "laptop", 999.99])
    _ = apply(Map.get(products, :__reflaxe_class__) || Map.get(products, :__struct__), :set, [products, "mouse", 25.5])
    _ = apply(Map.get(products, :__reflaxe_class__) || Map.get(products, :__struct__), :set, [products, "keyboard", 75])
    descriptions = []
    total_value = 0
    g = apply(Map.get(products, :__reflaxe_class__) || Map.get(products, :__struct__), :key_value_iterator, [products])
    {_descriptions, _total_value} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {descriptions, total_value}, fn _, {acc_descriptions, acc_total_value} ->
      try do
        if (g.has_next.()) do
          product = g.next.().key
          price = g.next.().value
          acc_descriptions = acc_descriptions ++ ["" <> product <> " ($" <> Kernel.to_string(price) <> ")"]
          acc_total_value = acc_total_value + price
          {:cont, {acc_descriptions, acc_total_value}}
        else
          {:halt, {acc_descriptions, acc_total_value}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_descriptions, acc_total_value}}
        :throw, :continue ->
          {:cont, {acc_descriptions, acc_total_value}}
      end
    end)
    nil
  end
end
