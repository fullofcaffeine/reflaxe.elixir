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
    case (elem(topic, 0)) do
      0 ->
        "todo:updates"
      1 ->
        "user:activity"
      2 ->
        "system:notifications"
    end
  end
  def message_to_elixir(_message) do
    Phoenix.SafePubSub.add_timestamp(base_payload)
  end
  def parse_message_impl(msg) do
    if (not Phoenix.SafePubSub.is_valid_message(msg)) do
      Log.trace(Phoenix.SafePubSub.create_malformed_message_error(msg), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 191, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
      :none
    end
    case (g) do
      "bulk_update" ->
        if (msg.action != nil) do
          case (bulk_action) do
            {:some, action} ->
              {:some, {:BulkUpdate, (g)}}
            :none ->
              :none
          end
        else
          :none
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          case (alert_level) do
            {:some, msg} ->
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
  defp bulk_action_to_string(action) do
    case (elem(action, 0)) do
      0 ->
        "complete_all"
      1 ->
        "delete_completed"
      2 ->
        "set_priority"
      3 ->
        "add_tag"
      4 ->
        "remove_tag"
    end
  end
  defp parse_bulk_action(action) do
    case (action) do
      "add_tag" ->
        {:AddTag, ""}
      "complete_all" ->
        {:CompleteAll}
      "delete_completed" ->
        {:DeleteCompleted}
      "remove_tag" ->
        {:RemoveTag, ""}
      "set_priority" ->
        {:SetPriority, {:Medium}}
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
        {:Critical}
      "error" ->
        {:Error}
      "info" ->
        {:Info}
      "warning" ->
        {:Warning}
      _ ->
        :none
    end
  end
end