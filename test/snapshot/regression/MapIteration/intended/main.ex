defmodule Main do
  def main() do
    test_simple_map_iteration()
    test_key_only_iteration()
    test_value_only_iteration()
    test_map_comprehension()
    test_nested_map_iteration()
    test_map_iteration_with_filter()
    test_map_iteration_with_accumulation()
  end
  defp test_simple_map_iteration() do
    colors = %{}
    colors = colors |> Map.put("red", "#FF0000") |> Map.put("green", "#00FF00") |> Map.put("blue", "#0000FF")
    seen = 0
    g = Reflaxe.Elixir.IMap.key_value_iterator(colors)
    {seen} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {seen}, fn _, {acc_seen} ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_0 ->
          (case Map.fetch(reflaxe_structural_receiver_node_0, :has_next) do
            {:ok, reflaxe_structural_callback_node_0} ->
              reflaxe_structural_callback_node_0.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_0, :__struct__), :has_next, [reflaxe_structural_receiver_node_0])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_1 ->
              (case Map.fetch(reflaxe_structural_receiver_node_1, :next) do
                {:ok, reflaxe_structural_callback_node_1} ->
                  reflaxe_structural_callback_node_1.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_1, :__struct__), :next, [reflaxe_structural_receiver_node_1])
              end)
          end)
          name = g.key
          hex = g.value
          if (Map.get(colors, name) != hex) do
            raise Reflaxe.Elixir.HaxeThrow, [value: "Map iteration detached a key from its value"]
          end
          acc_seen = acc_seen + 1
          {:cont, {acc_seen}}
        else
          {:halt, {acc_seen}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_seen}}
        :throw, :continue ->
          {:cont, {acc_seen}}
      end
    end)
    if (seen != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Map iteration lost an entry"]
    end
  end
  defp test_key_only_iteration() do
    inventory = %{}
    inventory = inventory |> Map.put("apples", 10) |> Map.put("oranges", 5) |> Map.put("bananas", 8)
    keys = []
    g = Reflaxe.Elixir.IMap.key_value_iterator(inventory)
    {keys} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {keys}, fn _, {acc_keys} ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_2 ->
          (case Map.fetch(reflaxe_structural_receiver_node_2, :has_next) do
            {:ok, reflaxe_structural_callback_node_2} ->
              reflaxe_structural_callback_node_2.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_2, :__struct__), :has_next, [reflaxe_structural_receiver_node_2])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_3 ->
              (case Map.fetch(reflaxe_structural_receiver_node_3, :next) do
                {:ok, reflaxe_structural_callback_node_3} ->
                  reflaxe_structural_callback_node_3.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_3, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_3, :__struct__), :next, [reflaxe_structural_receiver_node_3])
              end)
          end)
          item = g.key
          _ = g.value
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
    if ((length(keys) != 3 or (case Enum.find_index(keys, fn item -> item == "apples" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(keys, fn item -> item == "oranges" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(keys, fn item -> item == "bananas" end) do
      nil -> -1
      index -> index
    end) < 0)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Key-only iteration lost or duplicated a key"]
    end
  end
  defp test_value_only_iteration() do
    scores = %{}
    scores = scores |> Map.put("Alice", 95) |> Map.put("Bob", 87) |> Map.put("Charlie", 92)
    total = 0
    g = Reflaxe.Elixir.IMap.key_value_iterator(scores)
    {total} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total}, fn _, {acc_total} ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_4 ->
          (case Map.fetch(reflaxe_structural_receiver_node_4, :has_next) do
            {:ok, reflaxe_structural_callback_node_4} ->
              reflaxe_structural_callback_node_4.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_4, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_4, :__struct__), :has_next, [reflaxe_structural_receiver_node_4])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_5 ->
              (case Map.fetch(reflaxe_structural_receiver_node_5, :next) do
                {:ok, reflaxe_structural_callback_node_5} ->
                  reflaxe_structural_callback_node_5.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_5, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_5, :__struct__), :next, [reflaxe_structural_receiver_node_5])
              end)
          end)
          _ = g.key
          score = g.value
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
    if (total != 274) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Value-only iteration lost accumulated state"]
    end
  end
  defp test_map_comprehension() do
    prices = %{}
    prices = prices |> Map.put("apple", 1.5) |> Map.put("orange", 2) |> Map.put("banana", 0.75)
    g_value = Reflaxe.Elixir.IMap.key_value_iterator(prices)
    {discounted} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[]}, fn _, {acc__g} ->
      try do
        if ((case g_value do
        reflaxe_structural_receiver_node_6 ->
          (case Map.fetch(reflaxe_structural_receiver_node_6, :has_next) do
            {:ok, reflaxe_structural_callback_node_6} ->
              reflaxe_structural_callback_node_6.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_6, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_6, :__struct__), :has_next, [reflaxe_structural_receiver_node_6])
          end)
      end)) do
          g_value = (case g_value do
            reflaxe_structural_receiver_node_7 ->
              (case Map.fetch(reflaxe_structural_receiver_node_7, :next) do
                {:ok, reflaxe_structural_callback_node_7} ->
                  reflaxe_structural_callback_node_7.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_7, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_7, :__struct__), :next, [reflaxe_structural_receiver_node_7])
              end)
          end)
          item = g_value.key
          price = g_value.value
          acc__g = acc__g ++ ["" <> item <> ": $" <> Reflaxe.Elixir.HaxeFloat.to_string(Reflaxe.Elixir.HaxeFloat.mul(price, 0.9))]
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
    if ((length(discounted) != 3 or (case Enum.find_index(discounted, fn item -> item == "apple: $1.35" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(discounted, fn item -> item == "orange: $1.8" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(discounted, fn item -> item == "banana: $0.675" end) do
      nil -> -1
      index -> index
    end) < 0)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Map comprehension changed its transformed entries"]
    end
  end
  defp test_nested_map_iteration() do
    departments = %{}
    engineering = %{}
    engineering = engineering |> Map.put("Alice", 5) |> Map.put("Bob", 3)
    departments = Map.put(departments, "Engineering", engineering)
    sales = %{}
    sales = sales |> Map.put("Charlie", 7) |> Map.put("Diana", 4)
    departments = Map.put(departments, "Sales", sales)
    count = 0
    total_years = 0
    g = Reflaxe.Elixir.IMap.key_value_iterator(departments)
    {count, total_years} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count, total_years}, fn _, {acc_count, acc_total_years} ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_8 ->
          (case Map.fetch(reflaxe_structural_receiver_node_8, :has_next) do
            {:ok, reflaxe_structural_callback_node_8} ->
              reflaxe_structural_callback_node_8.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_8, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_8, :__struct__), :has_next, [reflaxe_structural_receiver_node_8])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_9 ->
              (case Map.fetch(reflaxe_structural_receiver_node_9, :next) do
                {:ok, reflaxe_structural_callback_node_9} ->
                  reflaxe_structural_callback_node_9.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_9, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_9, :__struct__), :next, [reflaxe_structural_receiver_node_9])
              end)
          end)
          _dept = g.key
          employees = g.value
          g = Reflaxe.Elixir.IMap.key_value_iterator(employees)
          {acc_count, acc_total_years} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_count, acc_total_years}, fn _, {acc_count, acc_total_years} ->
            try do
              if ((case g do
              reflaxe_structural_receiver_node_10 ->
                (case Map.fetch(reflaxe_structural_receiver_node_10, :has_next) do
                  {:ok, reflaxe_structural_callback_node_10} ->
                    reflaxe_structural_callback_node_10.()
                  :error ->
                    apply(Map.get(reflaxe_structural_receiver_node_10, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_10, :__struct__), :has_next, [reflaxe_structural_receiver_node_10])
                end)
            end)) do
                g = (case g do
                  reflaxe_structural_receiver_node_11 ->
                    (case Map.fetch(reflaxe_structural_receiver_node_11, :next) do
                      {:ok, reflaxe_structural_callback_node_11} ->
                        reflaxe_structural_callback_node_11.()
                      :error ->
                        apply(Map.get(reflaxe_structural_receiver_node_11, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_11, :__struct__), :next, [reflaxe_structural_receiver_node_11])
                    end)
                end)
                _name = g.key
                years = g.value
                acc_count = acc_count + 1
                acc_total_years = acc_total_years + years
                {:cont, {acc_count, acc_total_years}}
              else
                {:halt, {acc_count, acc_total_years}}
              end
            catch
              :throw, {:break, break_state} ->
                {:halt, break_state}
              :throw, {:continue, continue_state} ->
                {:cont, continue_state}
              :throw, :break ->
                {:halt, {acc_count, acc_total_years}}
              :throw, :continue ->
                {:cont, {acc_count, acc_total_years}}
            end
          end)
          {:cont, {acc_count, acc_total_years}}
        else
          {:halt, {acc_count, acc_total_years}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_count, acc_total_years}}
        :throw, :continue ->
          {:cont, {acc_count, acc_total_years}}
      end
    end)
    if (count != 4 or total_years != 19) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested map iteration lost accumulated state"]
    end
  end
  defp test_map_iteration_with_filter() do
    ages = %{}
    ages = ages |> Map.put("Alice", 25) |> Map.put("Bob", 17) |> Map.put("Charlie", 30) |> Map.put("Diana", 16)
    adults = []
    g = Reflaxe.Elixir.IMap.key_value_iterator(ages)
    {adults} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {adults}, fn _, {acc_adults} ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_12 ->
          (case Map.fetch(reflaxe_structural_receiver_node_12, :has_next) do
            {:ok, reflaxe_structural_callback_node_12} ->
              reflaxe_structural_callback_node_12.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_12, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_12, :__struct__), :has_next, [reflaxe_structural_receiver_node_12])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_13 ->
              (case Map.fetch(reflaxe_structural_receiver_node_13, :next) do
                {:ok, reflaxe_structural_callback_node_13} ->
                  reflaxe_structural_callback_node_13.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_13, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_13, :__struct__), :next, [reflaxe_structural_receiver_node_13])
              end)
          end)
          name = g.key
          age = g.value
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
    if ((length(adults) != 2 or (case Enum.find_index(adults, fn item -> item == "Alice" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(adults, fn item -> item == "Charlie" end) do
      nil -> -1
      index -> index
    end) < 0)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Filtered map iteration selected the wrong entries"]
    end
  end
  defp test_map_iteration_with_accumulation() do
    products = %{}
    products = products |> Map.put("laptop", 999.99) |> Map.put("mouse", 25.5) |> Map.put("keyboard", 75)
    descriptions = []
    total_value = 0
    g = Reflaxe.Elixir.IMap.key_value_iterator(products)
    {descriptions, total_value} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {descriptions, total_value}, fn _, {acc_descriptions, acc_total_value} ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_14 ->
          (case Map.fetch(reflaxe_structural_receiver_node_14, :has_next) do
            {:ok, reflaxe_structural_callback_node_14} ->
              reflaxe_structural_callback_node_14.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_14, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_14, :__struct__), :has_next, [reflaxe_structural_receiver_node_14])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_15 ->
              (case Map.fetch(reflaxe_structural_receiver_node_15, :next) do
                {:ok, reflaxe_structural_callback_node_15} ->
                  reflaxe_structural_callback_node_15.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_15, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_15, :__struct__), :next, [reflaxe_structural_receiver_node_15])
              end)
          end)
          product = g.key
          price = g.value
          acc_descriptions = acc_descriptions ++ ["" <> product <> " ($" <> Reflaxe.Elixir.HaxeFloat.to_string(price) <> ")"]
          acc_total_value = Reflaxe.Elixir.HaxeFloat.add(acc_total_value, price)
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
    if (length(descriptions) != 3 or Reflaxe.Elixir.HaxeFloat.gt(Reflaxe.Elixir.HaxeFloat.abs(Reflaxe.Elixir.HaxeFloat.sub(total_value, 1100.49)), 1.0e-06)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Map iteration lost array or numeric accumulator state"]
    end
  end
end
