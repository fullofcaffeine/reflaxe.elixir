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
    %{:type => "todo_created", :todo => (g)}
  1 ->
    g = elem(_message, 1)
    %{:type => "todo_updated", :todo => (g)}
  2 ->
    g = elem(_message, 1)
    %{:type => "todo_deleted", :todo_id => (g)}
  3 ->
    g = elem(_message, 1)
    %{:type => "bulk_update", :action => bulk_action_to_string((g))}
  4 ->
    g = elem(_message, 1)
    %{:type => "user_online", :user_id => (g)}
  5 ->
    g = elem(_message, 1)
    %{:type => "user_offline", :user_id => (g)}
  6 ->
    g = elem(_message, 1)
    g1 = elem(_message, 2)
    message = g
    level = g1
    %{:type => "system_alert", :message => message, :level => alert_level_to_string(level)}
end
    Phoenix.SafePubSub.add_timestamp(base_payload)
  end
  def parse_message_impl(msg) do
    if (not Phoenix.SafePubSub.is_valid_message(msg)) do
      Log.trace(Phoenix.SafePubSub.create_malformed_message_error(msg), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 191, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
      :none
    end
    g = msg.type
    case (g) do
      "bulk_update" ->
        if (msg.action != nil) do
          bulk_action = parse_bulk_action(msg.action)
          case (bulk_action) do
            {:some, _} ->
              g = elem(bulk_action, 1)
              {:some, {:BulkUpdate, (g)}}
            :none ->
              :none
          end
        else
          :none
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          alert_level = parse_alert_level(msg.level)
          case (alert_level) do
            {:some, _} ->
              g = elem(alert_level, 1)
              {:some, {:SystemAlert, msg.message, (g)}}
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
        Log.trace(Phoenix.SafePubSub.create_unknown_message_error(msg.type), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 223, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
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