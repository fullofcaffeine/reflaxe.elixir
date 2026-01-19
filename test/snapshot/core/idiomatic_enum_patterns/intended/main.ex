defmodule Main do
  def main() do
    _ = test_message_conversion()
    _ = test_bulk_action_to_string()
    _ = test_nested_enum_patterns()
  end
  defp message_to_elixir(message) do
    base_payload = (case message do
      {:todo_created, todo} -> %{:type => "todo_created", :todo => todo}
      {:todo_updated, todo} -> %{:type => "todo_updated", :todo => todo}
      {:todo_deleted, id} -> %{:type => "todo_deleted", :todo_id => id}
      {:bulk_update, action} -> %{:type => "bulk_update", :action => action}
      {:user_online, user_id} -> %{:type => "user_online", :user_id => user_id}
      {:user_offline, user_id} -> %{:type => "user_offline", :user_id => user_id}
      {:system_alert, message, level} -> %{:type => "system_alert", :message => message, :level => level}
    end)
    _ = add_timestamp(base_payload)
  end
  defp bulk_action_to_string(action) do
    (case action do
      {:complete_all} -> "complete_all"
      {:delete_completed} -> "delete_completed"
      {:set_priority, priority} -> "set_priority:#{priority}"
      {:add_tag, tag} -> "add_tag:#{tag}"
      {:remove_tag, tag} -> "remove_tag:#{tag}"
    end)
  end
  defp process_complex_message(msg) do
    (case msg do
      {:todo_created, _todo} -> "New todo created"
      {:todo_updated, _todo} -> "Todo updated"
      {:todo_deleted, id} -> "Todo #{Kernel.to_string(id)} deleted"
      {:bulk_update, action} ->
        action_str = (case parse_bulk_action(action) do
          {:complete_all} -> "Completing all todos"
          {:delete_completed} -> "Deleting completed todos"
          {:set_priority, p} -> "Setting priority to #{p}"
          {:add_tag, t} -> "Adding tag: #{t}"
          {:remove_tag, t} -> "Removing tag: #{t}"
        end)
        "Bulk operation: #{action_str}"
      {:user_online, user_id} -> "User #{Kernel.to_string(user_id)} is online"
      {:user_offline, user_id} -> "User #{Kernel.to_string(user_id)} is offline"
      {:system_alert, _message, level} -> "#{level}: #{msg}"
    end)
  end
  defp add_timestamp(payload) do
    payload
  end
  defp parse_bulk_action(action) do
    (case action do
      "complete_all" -> {:complete_all}
      "delete_completed" -> {:delete_completed}
      str ->
        str = action
        cond_value = (case :binary.match(str, "set_priority:") do
          {pos, _} -> pos
          :nomatch -> -1
        end)
        if (cond_value == 0) do
          {:set_priority, String.slice(str, 13..-1//1)}
        else
          str = action
          cond_value = (case :binary.match(str, "add_tag:") do
            {pos, _} -> pos
            :nomatch -> -1
          end)
          if (cond_value == 0) do
            {:add_tag, String.slice(str, 8..-1//1)}
          else
            str = action
            cond_value = (case :binary.match(str, "remove_tag:") do
              {pos, _} -> pos
              :nomatch -> -1
            end)
            if (cond_value == 0), do: {:remove_tag, String.slice(str, 11..-1//1)}, else: {:complete_all}
          end
        end
    end)
  end
  defp test_message_conversion() do
    msg1 = {:todo_created, %{:id => 1, :title => "Test"}}
    msg2 = {:todo_deleted, 42}
    msg3 = {:system_alert, "Server restarting", "warning"}
    _ = message_to_elixir(msg1)
    _ = message_to_elixir(msg2)
    _ = message_to_elixir(msg3)
    nil
  end
  defp test_bulk_action_to_string() do
    action1 = {:complete_all}
    action2 = {:set_priority, "high"}
    action3 = {:add_tag, "urgent"}
    _ = bulk_action_to_string(action1)
    _ = bulk_action_to_string(action2)
    _ = bulk_action_to_string(action3)
    nil
  end
  defp test_nested_enum_patterns() do
    msg1 = {:bulk_update, "complete_all"}
    msg2 = {:bulk_update, "set_priority:high"}
    msg3 = {:user_online, 123}
    _ = process_complex_message(msg1)
    _ = process_complex_message(msg2)
    _ = process_complex_message(msg3)
    nil
  end
end
