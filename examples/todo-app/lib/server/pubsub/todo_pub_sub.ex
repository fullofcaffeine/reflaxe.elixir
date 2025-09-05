defmodule TodoPubSub do
  def subscribe(topic) do
    Phoenix.SafePubSub.subscribe_with_converter(topic, TodoPubSub.topicToString)
  end
  def broadcast(topic, message) do
    Phoenix.SafePubSub.broadcast_with_converters(topic, message, TodoPubSub.topicToString, TodoPubSub.messageToElixir)
  end
  def parse_message(msg) do
    Phoenix.SafePubSub.parse_with_converter(msg, TodoPubSub.parseMessageImpl)
  end
  defp topic_to_string(topic) do
    case (elem(topic, 0)) do
      0 ->
        "todo:updates"
      1 ->
        "user:activity"
      2 ->
        "system:notifications"
    end
  end
  defp message_to_elixir(message) do
    base_payload = case (elem(message, 0)) do
  0 ->
    g = elem(message, 1)
    todo = g
    %{:type => "todo_created", :todo => todo}
  1 ->
    g = elem(message, 1)
    todo = g
    %{:type => "todo_updated", :todo => todo}
  2 ->
    g = elem(message, 1)
    id = g
    %{:type => "todo_deleted", :todo_id => id}
  3 ->
    g = elem(message, 1)
    action = g
    %{:type => "bulk_update", :action => bulk_action_to_string(action)}
  4 ->
    g = elem(message, 1)
    user_id = g
    %{:type => "user_online", :user_id => user_id}
  5 ->
    g = elem(message, 1)
    user_id = g
    %{:type => "user_offline", :user_id => user_id}
  6 ->
    g = elem(message, 1)
    g1 = elem(message, 2)
    message = g
    level = g1
    %{:type => "system_alert", :message => message, :level => alert_level_to_string(level)}
end
    Phoenix.SafePubSub.add_timestamp(base_payload)
  end
  defp parse_message_impl(msg) do
    if (not Phoenix.SafePubSub.is_valid_message(msg)) do
      Log.trace(Phoenix.SafePubSub.create_malformed_message_error(msg), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 188, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
      :none
    end
    g = msg.type
    case (g) do
      "bulk_update" ->
        if (msg.action != nil) do
          bulk_action = parse_bulk_action(msg.action)
          case (elem(bulk_action, 0)) do
            0 ->
              g = elem(bulk_action, 1)
              action = g
              {:Some, {:BulkUpdate, action}}
            1 ->
              :none
          end
        else
          :none
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          alert_level = parse_alert_level(msg.level)
          case (elem(alert_level, 0)) do
            0 ->
              g = elem(alert_level, 1)
              level = g
              {:Some, {:SystemAlert, msg.message, level}}
            1 ->
              :none
          end
        else
          :none
        end
      "todo_created" ->
        if (msg.todo != nil), do: {:Some, {:TodoCreated, msg.todo}}, else: :none
      "todo_deleted" ->
        if (msg.todo_id != nil), do: {:Some, {:TodoDeleted, msg.todo_id}}, else: :none
      "todo_updated" ->
        if (msg.todo != nil), do: {:Some, {:TodoUpdated, msg.todo}}, else: :none
      "user_offline" ->
        if (msg.user_id != nil), do: {:Some, {:UserOffline, msg.user_id}}, else: :none
      "user_online" ->
        if (msg.user_id != nil), do: {:Some, {:UserOnline, msg.user_id}}, else: :none
      _ ->
        Log.trace(Phoenix.SafePubSub.create_unknown_message_error(msg.type), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 220, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
        :none
    end
  end
  defp bulk_action_to_string(action) do
    case (elem(action, 0)) do
      0 ->
        "complete_all"
      1 ->
        "delete_completed"
      2 ->
        g = elem(action, 1)
        _priority = g
        "set_priority"
      3 ->
        g = elem(action, 1)
        _tag = g
        "add_tag"
      4 ->
        g = elem(action, 1)
        _tag = g
        "remove_tag"
    end
  end
  defp parse_bulk_action(action) do
    case (action) do
      "add_tag" ->
        {:Some, {:AddTag, ""}}
      "complete_all" ->
        {:Some, :complete_all}
      "delete_completed" ->
        {:Some, :delete_completed}
      "remove_tag" ->
        {:Some, {:RemoveTag, ""}}
      "set_priority" ->
        {:Some, {:SetPriority, :medium}}
      _ ->
        :none
    end
  end
  defp alert_level_to_string(level) do
    case (elem(level, 0)) do
      0 ->
        "info"
      1 ->
        "warning"
      2 ->
        "error"
      3 ->
        "critical"
    end
  end
  defp parse_alert_level(level) do
    case (level) do
      "critical" ->
        {:Some, :critical}
      "error" ->
        {:Some, :error}
      "info" ->
        {:Some, :info}
      "warning" ->
        {:Some, :warning}
      _ ->
        :none
    end
  end
end