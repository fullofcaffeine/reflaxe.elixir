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
    colors = colors |> Map.put("red", "#FF0000") |> Map.put("green", "#00FF00") |> Map.put("blue", "#0000FF")
    g = Reflaxe.Elixir.IMap.key_value_iterator(colors)
    _ =
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
        try do
          if (g.has_next.()) do
            _name = g.next.().key
            _hex = g.next.().value
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
    inventory = inventory |> Map.put("apples", 10) |> Map.put("oranges", 5) |> Map.put("bananas", 8)
    keys = []
    g = Reflaxe.Elixir.IMap.key_value_iterator(inventory)
    {_keys} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {keys}, fn _, {acc_keys} ->
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
    scores = scores |> Map.put("Alice", 95) |> Map.put("Bob", 87) |> Map.put("Charlie", 92)
    total = 0
    g = Reflaxe.Elixir.IMap.key_value_iterator(scores)
    {_total} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total}, fn _, {acc_total} ->
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
    prices = prices |> Map.put("apple", 1.5) |> Map.put("orange", 2) |> Map.put("banana", 0.75)
    g_value = Reflaxe.Elixir.IMap.key_value_iterator(prices)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[]}, fn _, {acc__g} ->
      try do
        if (g_value.has_next.()) do
          item = g_value.next.().key
          price = g_value.next.().value
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
    _discounted = []
    nil
  end
  defp test_nested_map_iteration() do
    departments = %{}
    engineering = %{}
    engineering = engineering |> Map.put("Alice", 5) |> Map.put("Bob", 3)
    departments = Map.put(departments, "Engineering", engineering)
    sales = %{}
    sales = sales |> Map.put("Charlie", 7) |> Map.put("Diana", 4)
    departments = Map.put(departments, "Sales", sales)
    g = Reflaxe.Elixir.IMap.key_value_iterator(departments)
    _ =
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
        try do
          if (g.has_next.()) do
            _dept = g.next.().key
            employees = g.next.().value
            g = Reflaxe.Elixir.IMap.key_value_iterator(employees)
            _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
              try do
                if (g.has_next.()) do
                  _name = g.next.().key
                  _years = g.next.().value
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
    ages = ages |> Map.put("Alice", 25) |> Map.put("Bob", 17) |> Map.put("Charlie", 30) |> Map.put("Diana", 16)
    adults = []
    g = Reflaxe.Elixir.IMap.key_value_iterator(ages)
    {_adults} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {adults}, fn _, {acc_adults} ->
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
    products = products |> Map.put("laptop", 999.99) |> Map.put("mouse", 25.5) |> Map.put("keyboard", 75)
    descriptions = []
    total_value = 0
    g = Reflaxe.Elixir.IMap.key_value_iterator(products)
    {_descriptions, _total_value} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {descriptions, total_value}, fn _, {acc_descriptions, acc_total_value} ->
      try do
        if (g.has_next.()) do
          product = g.next.().key
          price = g.next.().value
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
    nil
  end
end
