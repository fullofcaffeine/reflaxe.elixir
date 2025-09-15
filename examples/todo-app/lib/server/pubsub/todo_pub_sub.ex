defmodule TodoPubSub do
  @compile [{:nowarn_unused_function, [{:_parse_bulk_action, 1}, {:_parse_alert_level, 1}, {:_bulk_action_to_string, 1}, {:_alert_level_to_string, 1}]}]

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
    case (topic) do
      {:todo_updates} ->
        "todo:updates"
      {:user_activity} ->
        "user:activity"
      {:system_notifications} ->
        "system:notifications"
    end
  end
  def message_to_elixir(message) do
    base_payload = case (message) do
  {:todo_created, _todo} ->
    g = elem(message, 1)
    %{:type => "todo_created", :todo => (g)}
  {:todo_updated, _todo} ->
    g = elem(message, 1)
    %{:type => "todo_updated", :todo => (g)}
  {:todo_deleted, _id} ->
    g = elem(message, 1)
    %{:type => "todo_deleted", :todo_id => (g)}
  {:bulk_update, _action} ->
    g = elem(message, 1)
    action = g
    %{:type => "bulk_update", :action => TodoPubSub.bulk_action_to_string(action)}
  {:user_online, _user_id} ->
    g = elem(message, 1)
    %{:type => "user_online", :user_id => (g)}
  {:user_offline, _user_id} ->
    g = elem(message, 1)
    %{:type => "user_offline", :user_id => (g)}
  {:system_alert, _message, _level} ->
    message = g
    level = g1
    %{:type => "system_alert", :message => message, :level => TodoPubSub.alert_level_to_string(level)}
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
          bulk_action = TodoPubSub.parse_bulk_action(msg.action)
          case (bulk_action) do
            {:some, g} ->
              {:some, {:bulk_update, (g)}}
            {:none} ->
              :none
          end
        else
          :none
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          alert_level = TodoPubSub.parse_alert_level(msg.level)
          case (alert_level) do
            {:some, g} ->
              {:some, {:system_alert, msg.message, (g)}}
            {:none} ->
              :none
          end
        else
          :none
        end
      "todo_created" ->
        if (msg.todo != nil), do: {:todo_created, msg.todo}, else: :none
      "todo_deleted" ->
        if (msg.todo_id != nil), do: {:todo_deleted, msg.todo_id}, else: :none
      "todo_updated" ->
        if (msg.todo != nil), do: {:todo_updated, msg.todo}, else: :none
      "user_offline" ->
        if (msg.user_id != nil), do: {:user_offline, msg.user_id}, else: :none
      "user_online" ->
        if (msg.user_id != nil), do: {:user_online, msg.user_id}, else: :none
      _ ->
        Log.trace(Phoenix.SafePubSub.create_unknown_message_error(msg.type), %{:file_name => "src_haxe/server/pubsub/TodoPubSub.hx", :line_number => 223, :class_name => "server.pubsub.TodoPubSub", :method_name => "parseMessageImpl"})
        :none
    end
  end
  defp _bulk_action_to_string(action) do
    case (action) do
      {:complete_all} ->
        "complete_all"
      {:delete_completed} ->
        "delete_completed"
      {:set_priority, _priority} ->
        _priority = g
        "set_priority"
      {:add_tag, _tag} ->
        _tag = g
        "add_tag"
      {:remove_tag, _tag} ->
        _tag = g
        "remove_tag"
    end
  end
  defp _parse_bulk_action(action) do
    case (action) do
      "add_tag" ->
        {:add_tag, ""}
      "complete_all" ->
        {:complete_all}
      "delete_completed" ->
        {:delete_completed}
      "remove_tag" ->
        {:remove_tag, ""}
      "set_priority" ->
        {:set_priority, {:medium}}
      _ ->
        :none
    end
  end
  defp _alert_level_to_string(level) do
    case (level) do
      {:info} ->
        "info"
      {:warning} ->
        "warning"
      {:error} ->
        "error"
      {:critical} ->
        "critical"
    end
  end
  defp _parse_alert_level(level) do
    case (level) do
      "critical" ->
        {:critical}
      "error" ->
        {:error}
      "info" ->
        {:info}
      "warning" ->
        {:warning}
      _ ->
        :none
    end
  end
end