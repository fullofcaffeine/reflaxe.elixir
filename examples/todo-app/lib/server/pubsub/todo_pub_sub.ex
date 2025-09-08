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
  def topic_to_string(_topic) do
    case (elem(_topic, 0)) do
      0 ->
        "todo:updates"
      1 ->
        "user:activity"
      2 ->
        "system:notifications"
    end
  end
  def message_to_elixir(_message) do
    base_payload = case (elem(_message, 0)) do
  0 ->
    g = elem(_message, 1)
    todo = g
    %{:type => "todo_created", :todo => todo}
  1 ->
    g = elem(_message, 1)
    todo = g
    %{:type => "todo_updated", :todo => todo}
  2 ->
    g = elem(_message, 1)
    id = g
    %{:type => "todo_deleted", :todo_id => id}
  3 ->
    g = elem(_message, 1)
    action = g
    %{:type => "bulk_update", :action => TodoPubSub.bulk_action_to_string(action)}
  4 ->
    g = elem(_message, 1)
    user_id = g
    %{:type => "user_online", :user_id => user_id}
  5 ->
    g = elem(_message, 1)
    user_id = g
    %{:type => "user_offline", :user_id => user_id}
  6 ->
    g = elem(_message, 1)
    g1 = elem(_message, 2)
    message = g
    level = g1
    %{:type => "system_alert", :message => message, :level => TodoPubSub.alert_level_to_string(level)}
end
    Phoenix.SafePubSub.add_timestamp(base_payload)
  end
  def parse_message_impl(msg) do
    if (not Phoenix.SafePubSub.is_valid_message(msg)) do
      Log.trace(Phoenix.SafePubSub.create_malformed_message_error(msg), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 191, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
      :none
    end
    g = msg.type
    case (g) do
      "bulk_update" ->
        if (msg.action != nil) do
          bulk_action = TodoPubSub.parse_bulk_action(msg.action)
          case (bulk_action) do
            {:some, _} ->
              g = elem(bulk_action, 1)
              action = g
              {:BulkUpdate, action}
            :none ->
              :none
          end
        else
          :none
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          alert_level = TodoPubSub.parse_alert_level(msg.level)
          case (alert_level) do
            {:some, _} ->
              g = elem(alert_level, 1)
              level = g
              {:SystemAlert, msg.message, level}
            :none ->
              :none
          end
        else
          :none
        end
      "todo_created" ->
        if (msg.todo != nil), do: {:TodoCreated, msg.todo}, else: :none
      "todo_deleted" ->
        if (msg.todo_id != nil), do: {:TodoDeleted, msg.todo_id}, else: :none
      "todo_updated" ->
        if (msg.todo != nil), do: {:TodoUpdated, msg.todo}, else: :none
      "user_offline" ->
        if (msg.user_id != nil), do: {:UserOffline, msg.user_id}, else: :none
      "user_online" ->
        if (msg.user_id != nil), do: {:UserOnline, msg.user_id}, else: :none
      _ ->
        Log.trace(Phoenix.SafePubSub.create_unknown_message_error(msg.type), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 223, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
        :none
    end
  end
  defp bulk_action_to_string(_action) do
    case (elem(_action, 0)) do
      0 ->
        "complete_all"
      1 ->
        "delete_completed"
      2 ->
        g = elem(_action, 1)
        _priority = g
        "set_priority"
      3 ->
        g = elem(_action, 1)
        _tag = g
        "add_tag"
      4 ->
        g = elem(_action, 1)
        _tag = g
        "remove_tag"
    end
  end
  defp parse_bulk_action(action) do
    case (action) do
      "add_tag" ->
        {:AddTag, ""}
      "complete_all" ->
        {0}
      "delete_completed" ->
        {1}
      "remove_tag" ->
        {:RemoveTag, ""}
      "set_priority" ->
        {:SetPriority, {1}}
      _ ->
        :none
    end
  end
  defp alert_level_to_string(_level) do
    case (elem(_level, 0)) do
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
        {3}
      "error" ->
        {2}
      "info" ->
        {0}
      "warning" ->
        {1}
      _ ->
        :none
    end
  end
end