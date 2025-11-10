defmodule TodoPubSub do
  alias Phoenix.SafePubSub, as: SafePubSub
  alias Phoenix.SafePubSub, as: SafePubSub
  alias Phoenix.SafePubSub, as: SafePubSub
  def broadcast(topic, message) do
    Phoenix.SafePubSub.broadcast_topic_payload(topic_to_string(topic), message_to_elixir(message))
  end
  def parse_message(msg) do
    Phoenix.SafePubSub.parse_with_converter(msg, fn m -> parse_message_impl(m) end)
  end
  def topic_to_string(topic) do
    (case topic do
      {:todo_updates} -> "todo:updates"
      {:user_activity} -> "user:activity"
      {:system_notifications} -> "system:notifications"
    end)
  end
  def message_to_elixir(message) do
    Phoenix.SafePubSub.add_timestamp((fn -> ((case message do
      {:todo_created, todo} -> %{:type => "todo_created", :todo => todo}
      {:todo_updated, todo} -> %{:type => "todo_updated", :todo => todo}
      {:todo_deleted, id} -> %{:type => "todo_deleted", :todo_id => id}
      {:bulk_update, action} -> %{:type => "bulk_update", :action => bulk_action_to_string(action)}
      {:user_online, user_id} -> %{:type => "user_online", :user_id => user_id}
      {:user_offline, user_id} -> %{:type => "user_offline", :user_id => user_id}
      {:system_alert, message2, level} -> %{:type => "system_alert", :message => message2, :level => alert_level_to_string(level)}
    end)) end).())
  end
  def parse_message_impl(msg) do
    if (not Phoenix.SafePubSub.is_valid_message(msg)) do
      Log.trace(SafePubSub.create_malformed_message_error(msg), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 168, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
      {:none}
    end
    (case Map.get(msg, :type) do
      "bulk_update" when Kernel.is_map_key(msg, :action) ->
        {:some, (case Map.get(msg, :action) do
  "add_tag" -> {:some, {:bulk_update, {:add_tag, ""}}}
  "complete_all" -> {:some, {:bulk_update, {:complete_all}}}
  "delete_completed" -> {:some, {:bulk_update, {:delete_completed}}}
  "remove_tag" -> {:some, {:bulk_update, {:remove_tag, ""}}}
  "set_priority" -> {:some, {:bulk_update, {:set_priority, {:medium}}}}
  _ -> {:none}
end)}
      "bulk_update" -> {:none}
      "system_alert" when Kernel.is_map_key(msg, :message) and Kernel.is_map_key(msg, :level) ->
        {:some, (case Map.get(msg, :level) do
  "critical" -> {:some, {:system_alert, Map.get(msg, :message), {:critical}}}
  "error" -> {:some, {:system_alert, Map.get(msg, :message), {:error}}}
  "info" -> {:some, {:system_alert, Map.get(msg, :message), {:info}}}
  "warning" -> {:some, {:system_alert, Map.get(msg, :message), {:warning}}}
  _ -> {:none}
end)}
      "system_alert" -> {:none}
      "todo_created" when Kernel.is_map_key(msg, :todo) -> {:some, {:todo_created, Map.get(msg, :todo)}}
      "todo_created" -> {:none}
      "todo_deleted" when Kernel.is_map_key(msg, :todo_id) -> {:some, {:todo_deleted, Map.get(msg, :todo_id)}}
      "todo_deleted" -> {:none}
      "todo_updated" when Kernel.is_map_key(msg, :todo) -> {:some, {:todo_updated, Map.get(msg, :todo)}}
      "todo_updated" -> {:none}
      "user_offline" when Kernel.is_map_key(msg, :user_id) -> {:some, {:user_offline, Map.get(msg, :user_id)}}
      "user_offline" -> {:none}
      "user_online" when Kernel.is_map_key(msg, :user_id) -> {:some, {:user_online, Map.get(msg, :user_id)}}
      "user_online" -> {:none}
      _ ->
        Log.trace(SafePubSub.create_unknown_message_error(Map.get(msg, :type)), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 205, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
        {:none}
    end)
  end
  defp bulk_action_to_string(action) do
    (case action do
      {:complete_all} -> "complete_all"
      {:delete_completed} -> "delete_completed"
      {:set_priority, _value} -> "set_priority"
      {:add_tag, _value} -> "add_tag"
      {:remove_tag, _value} -> "remove_tag"
    end)
  end
  defp alert_level_to_string(level) do
    (case level do
      {:info} -> "info"
      {:warning} -> "warning"
      {:error} -> "error"
      {:critical} -> "critical"
    end)
  end
end
