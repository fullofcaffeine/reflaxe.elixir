defmodule Main do
  def string_map() do
    map = %{}
    map = map |> Map.put("one", 1) |> Map.put("two", 2) |> Map.put("three", 3)
    map_remove_key_node_0 = "two"
    {map, _reflaxe_receiver_value_0} = {Map.delete(map, map_remove_key_node_0), Map.has_key?(map, map_remove_key_node_0)}
    Enum.reduce_while(Map.keys(map), :ok, fn _key, acc ->
      try do
        {:cont, acc}
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
    nil
  end
  def int_map() do
    map = %{}
    map = map |> Map.put(1, "first") |> Map.put(2, "second") |> Map.put(10, "tenth") |> Map.put(100, "hundredth")
    Enum.reduce_while(Map.keys(map), :ok, fn _key, acc ->
      try do
        {:cont, acc}
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
    Enum.reduce_while(Map.keys(map), {[]}, fn k, {acc__g} ->
      try do
        acc__g = acc__g ++ [k]
        {:cont, {acc__g}}
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
    _keys = []
    Enum.reduce_while(Map.keys(map), {[]}, fn k, {acc__g} ->
      try do
        acc__g = acc__g ++ [Map.get(map, k)]
        {:cont, {acc__g}}
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
    _values = []
    nil
  end
  def map_literals() do
    colors = %{"red" => 16711680, "green" => 65280, "blue" => 255}
    Enum.reduce_while(Map.keys(colors), :ok, fn color, acc ->
      try do
        _hex = StringTools.hex(Map.get(colors, color), 6)
        {:cont, acc}
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
    squares = %{1 => 1, 2 => 4, 3 => 9, 4 => 16, 5 => 25}
    Enum.reduce_while(Map.keys(squares), :ok, fn _n, acc ->
      try do
        {:cont, acc}
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
  def nested_maps() do
    users = %{}
    alice = %{}
    alice = alice |> Map.put("age", 30) |> Map.put("email", "alice@example.com") |> Map.put("active", true)
    bob = %{}
    bob = bob |> Map.put("age", 25) |> Map.put("email", "bob@example.com") |> Map.put("active", false)
    users = users |> Map.put("alice", alice) |> Map.put("bob", bob)
    Enum.reduce_while(Map.keys(users), :ok, fn username, acc ->
      try do
        user_data = Map.get(users, username)
        Enum.reduce_while(Map.keys(user_data), :ok, fn _field, acc ->
          try do
            {:cont, acc}
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
  def map_transformations() do
    original = %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}
    doubled = %{}
    {doubled} = Enum.reduce_while(Map.keys(original), {doubled}, fn key, {acc_doubled} ->
      try do
        value = Map.get(original, key) * 2
        acc_doubled = Map.put(acc_doubled, key, value)
        {:cont, {acc_doubled}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_doubled}}
        :throw, :continue ->
          {:cont, {acc_doubled}}
      end
    end)
    Enum.reduce_while(Map.keys(doubled), :ok, fn _key, acc ->
      try do
        {:cont, acc}
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
    filtered = %{}
    {filtered} = Enum.reduce_while(Map.keys(original), {filtered}, fn key, {acc_filtered} ->
      try do
        value = Map.get(original, key)
        acc_filtered = if (value > 2) do
          Map.put(acc_filtered, key, value)
        else
          acc_filtered
        end
        {:cont, {acc_filtered}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_filtered}}
        :throw, :continue ->
          {:cont, {acc_filtered}}
      end
    end)
    Enum.reduce_while(Map.keys(filtered), :ok, fn _key, acc ->
      try do
        {:cont, acc}
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
    map1 = %{"a" => 1, "b" => 2}
    map2 = %{"c" => 3, "d" => 4, "a" => 10}
    merged = %{}
    {merged} = Enum.reduce_while(Map.keys(map1), {merged}, fn key, {acc_merged} ->
      try do
        value = Map.get(map1, key)
        acc_merged = Map.put(acc_merged, key, value)
        {:cont, {acc_merged}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_merged}}
        :throw, :continue ->
          {:cont, {acc_merged}}
      end
    end)
    {merged} = Enum.reduce_while(Map.keys(map2), {merged}, fn key, {acc_merged} ->
      try do
        value = Map.get(map2, key)
        acc_merged = Map.put(acc_merged, key, value)
        {:cont, {acc_merged}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_merged}}
        :throw, :continue ->
          {:cont, {acc_merged}}
      end
    end)
    Enum.reduce_while(Map.keys(merged), :ok, fn _key, acc ->
      try do
        {:cont, acc}
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
  def enum_map() do
    map = %{}
    map = map |> Map.put({:red}, "FF0000") |> Map.put({:green}, "00FF00") |> Map.put({:blue}, "0000FF")
    Enum.reduce_while(Map.keys(map), :ok, fn _color, acc ->
      try do
        {:cont, acc}
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
    if (Map.has_key?(map, {:red})), do: nil
  end
  def process_map(input) do
    result = %{}
    {result} = Enum.reduce_while(Map.keys(input), {result}, fn key, {acc_result} ->
      try do
        value = Map.get(input, key)
        acc_result = Map.put(acc_result, key, "Value: " <> Reflaxe.Elixir.HaxeFloat.to_string(value))
        {:cont, {acc_result}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_result}}
        :throw, :continue ->
          {:cont, {acc_result}}
      end
    end)
    result
  end
  def collect_successful(input) do
    result = %{}
    {result} = Enum.reduce_while(Map.keys(input), {result}, fn key, {acc_result} ->
      try do
        acc_result =
          (case label_for(key) do
            {:present, value} ->
              Map.put(acc_result, key, value)
            {:missing} -> acc_result
          end)
        {:cont, {acc_result}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_result}}
        :throw, :continue ->
          {:cont, {acc_result}}
      end
    end)
    result
  end
  defp label_for(key) do
    if (key == "skip"), do: {:missing}, else: {:present, "Value: " <> key}
  end
  def main() do
    string_map()
    int_map()
    map_literals()
    nested_maps()
    map_transformations()
    enum_map()
    input = %{"x" => 10, "y" => 20, "z" => 30}
    output = process_map(input)
    Enum.reduce_while(Map.keys(output), :ok, fn _key, acc ->
      try do
        {:cont, acc}
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
end
