defmodule TodoPubSub do
  def subscribe(topic) do
    Phoenix.SafePubSub.subscribe_with_converter(topic, &TodoPubSub.topic_to_string/1)
  end
  def broadcast(topic, message) do
    Phoenix.SafePubSub.broadcast_with_converters(topic, message, &TodoPubSub.topic_to_string/1, &TodoPubSub.message_to_elixir/1)
  end
  def parse_message(msg) do
    Phoenix.SafePubSub.parse_with_converter(msg, &TodoPubSub.parse_message_impl/1)
  end
  def topic_to_string(topic) do
    temp_result = nil
    case (topic) do
      {:todo_updates} ->
        temp_result = "todo:updates"
      {:user_activity} ->
        temp_result = "user:activity"
      {:system_notifications} ->
        temp_result = "system:notifications"
    end
    temp_result
  end
  def message_to_elixir(message) do
    temp_struct = nil
    case (message) do
      {:todo_created, todo} ->
        todo = g
        temp_struct = %{:type => "todo_created", :todo => todo}
      {:todo_updated, todo} ->
        todo = g
        temp_struct = %{:type => "todo_updated", :todo => todo}
      {:todo_deleted, id} ->
        id = g
        temp_struct = %{:type => "todo_deleted", :todo_id => id}
      {:bulk_update, action} ->
        action = g
        temp_struct = %{:type => "bulk_update", :action => TodoPubSub.bulk_action_to_string(action)}
      {:user_online, user_id} ->
        user_id = g
        temp_struct = %{:type => "user_online", :user_id => user_id}
      {:user_offline, user_id} ->
        user_id = g
        temp_struct = %{:type => "user_offline", :user_id => user_id}
      {:system_alert, message2, level} ->
        message2 = g
        level = g1
        temp_struct = %{:type => "system_alert", :message => message2, :level => TodoPubSub.alert_level_to_string(level)}
    end
    Phoenix.SafePubSub.add_timestamp(temp_struct)
  end
  def parse_message_impl(msg) do
    if (not Phoenix.SafePubSub.is_valid_message(msg)) do
      Log.trace(Phoenix.SafePubSub.create_malformed_message_error(msg), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 191, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
      :none
    end
    temp_result = nil
    g = msg.type
    case (g) do
      "bulk_update" ->
        if (msg.action != nil) do
          bulk_action = TodoPubSub.parse_bulk_action(msg.action)
          case (bulk_action) do
            {:some, action} ->
              action = g2
              temp_result = {:bulk_update, action}
            {:none} ->
              temp_result = :none
          end
        else
          temp_result = :none
        end
      "system_alert" ->
        if (msg.message != nil and msg.level != nil) do
          alert_level = TodoPubSub.parse_alert_level(msg.level)
          case (alert_level) do
            {:some, level} ->
              level = g2
              temp_result = {:system_alert, msg.message, level}
            {:none} ->
              temp_result = :none
          end
        else
          temp_result = :none
        end
      "todo_created" ->
        if (msg.todo != nil) do
          temp_result = {:todo_created, msg.todo}
        else
          temp_result = :none
        end
      "todo_deleted" ->
        if (msg.todo_id != nil) do
          temp_result = {:todo_deleted, msg.todo_id}
        else
          temp_result = :none
        end
      "todo_updated" ->
        if (msg.todo != nil) do
          temp_result = {:todo_updated, msg.todo}
        else
          temp_result = :none
        end
      "user_offline" ->
        if (msg.user_id != nil) do
          temp_result = {:user_offline, msg.user_id}
        else
          temp_result = :none
        end
      "user_online" ->
        if (msg.user_id != nil) do
          temp_result = {:user_online, msg.user_id}
        else
          temp_result = :none
        end
      _ ->
        Log.trace(Phoenix.SafePubSub.create_unknown_message_error(msg.type), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 223, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
        temp_result = :none
    end
    temp_result
  end
  defp bulk_action_to_string(action) do
    temp_result = nil
    case (action) do
      {:complete_all} ->
        temp_result = "complete_all"
      {:delete_completed} ->
        temp_result = "delete_completed"
      {:set_priority, priority} ->
        priority = g
        temp_result = "set_priority"
      {:add_tag, tag} ->
        tag = g
        temp_result = "add_tag"
      {:remove_tag, tag} ->
        tag = g
        temp_result = "remove_tag"
    end
    temp_result
  end
  defp parse_bulk_action(action) do
    temp_result = nil
    case (action) do
      "add_tag" ->
        temp_result = {:add_tag, ""}
      "complete_all" ->
        temp_result = {:complete_all}
      "delete_completed" ->
        temp_result = {:delete_completed}
      "remove_tag" ->
        temp_result = {:remove_tag, ""}
      "set_priority" ->
        temp_result = {:set_priority, {:medium}}
      _ ->
        temp_result = :none
    end
    temp_result
  end
  defp alert_level_to_string(level) do
    temp_result = nil
    case (level) do
      {:info} ->
        temp_result = "info"
      {:warning} ->
        temp_result = "warning"
      {:error} ->
        temp_result = "error"
      {:critical} ->
        temp_result = "critical"
    end
    temp_result
  end
  defp parse_alert_level(level) do
    temp_result = nil
    case (level) do
      "critical" ->
        temp_result = {:critical}
      "error" ->
        temp_result = {:error}
      "info" ->
        temp_result = {:info}
      "warning" ->
        temp_result = {:warning}
      _ ->
        temp_result = :none
    end
    temp_result
  end
end