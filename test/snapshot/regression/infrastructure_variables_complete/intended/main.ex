defmodule Main do
  def main() do
    _ = test_basic_switch()
    _ = test_array_operations()
    _ = test_nested_loops()
    _ = test_filter_with_indexing()
    _ = test_map_iterator()
    _ = test_result_pattern_matching()
    _ = test_message_parsing()
    _ = test_mixed_real_world_patterns()
  end
  defp test_basic_switch() do
    msg_type = "test"
    msg_data = "hello"
    _result = if (msg_type == "test"), do: msg_data, else: "unknown"
    nil
  end
  defp test_array_operations() do
    items = ["a", "b", "c", "d"]
    _mapped = Enum.map(items, fn item -> String.upcase(item) end)
    numbers = [1, 2, 3, 4, 5]
    _filtered = Enum.filter(numbers, fn n -> n > 2 end)
    nil
  end
  defp test_nested_loops() do
    matrix = [[1, 2], [3, 4], [5, 6]]
    result = []
    _g = 0
    _ = Enum.reduce(matrix, result, fn row, result_acc ->
      _g = 0
      Enum.reduce(row, result_acc, fn item, result_acc -> Enum.concat(result_acc, [item * 2]) end)
    end)
    nil
  end
  defp test_filter_with_indexing() do
    items = [%{id: 1, name: "one"}, %{id: 2, name: "two"}, %{id: 3, name: "three"}]
    names = []
    _g = 0
    items_length = length(items)
    _ = Enum.reduce(0..(items_length - 1)//1, names, fn i, names_acc ->
      item = Enum.at(items, i)
      if (item.id > 1) do
        Enum.concat(names_acc, [item.name])
      else
        names_acc
      end
    end)
    nil
  end
  defp test_map_iterator() do
    user_map = %{}
    user_map = user_map |> Map.put(1, "Alice") |> Map.put(2, "Bob") |> Map.put(3, "Charlie")
    result = []
    g = Reflaxe.Elixir.IMap.key_value_iterator(user_map)
    {_result} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result}, fn _, {acc_result} ->
      try do
        if (g.has_next.()) do
          key = g.next.().key
          value = g.next.().value
          acc_result = acc_result ++ ["" <> Reflaxe.Elixir.HaxeFloat.to_string(key) <> ": " <> value]
          {:cont, {acc_result}}
        else
          {:halt, {acc_result}}
        end
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
    nil
  end
  defp test_result_pattern_matching() do
    results = [%{status: "ok", value: 42}, %{status: "error", value: -1}]
    _g = 0
    _ =
      Enum.each(results, fn result ->
        _output = (case result.status do
          "error" -> "Failed: " <> Reflaxe.Elixir.HaxeFloat.to_string(result.value)
          "ok" -> "Success: " <> Reflaxe.Elixir.HaxeFloat.to_string(result.value)
          _ -> "Unknown"
        end)
        nil
      end)
  end
  defp test_message_parsing() do
    messages = [%{type: "created", content: "New item"}, %{type: "updated", content: "Changed item"}, %{type: "deleted", content: "Removed item"}]
    parsed = Enum.map(messages, fn msg ->
      (case msg.type do
        "created" -> "Created: " <> msg.content
        "deleted" -> "Deleted: " <> msg.content
        "updated" -> "Updated: " <> msg.content
        _ -> "Unknown message"
      end)
    end)
    _g = 0
    _ = Enum.each(parsed, fn _ -> nil end)
  end
  defp test_mixed_real_world_patterns() do
    todos = [%{id: 1, title: "First", completed: false}, %{id: 2, title: "Second", completed: true}, %{id: 3, title: "Third", completed: false}]
    target_id = 2
    found = nil
    _g = 0
    todos_length = length(todos)
    found = Enum.reduce(0..(todos_length - 1)//1, found, fn i, found_acc ->
      if (Enum.at(todos, i).id == target_id) do
        found_acc = Enum.at(todos, i)
        throw(:break)
        found_acc
      else
        found_acc
      end
    end)
    if (not Kernel.is_nil(found)), do: nil
    completed_count = 0
    _g = 0
    _ = Enum.reduce(todos, completed_count, fn todo, completed_count_acc ->
      if (todo.completed) do
        completed_count_acc = completed_count_acc + 1
        completed_count_acc
      else
        completed_count_acc
      end
    end)
    titles = []
    _g = 0
    _ = Enum.reduce(todos, titles, fn todo, titles_acc ->
      if (not todo.completed) do
        titles_acc = Enum.concat(titles_acc, [String.upcase(todo.title)])
        titles_acc
      else
        titles_acc
      end
    end)
    nil
  end
end
