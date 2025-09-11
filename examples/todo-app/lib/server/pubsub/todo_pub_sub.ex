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
    case (_topic) do
      {:todoupdates} ->
        "todo:updates"
      {:useractivity} ->
        "user:activity"
      {:systemnotifications} ->
        "system:notifications"
    end
  end
  def message_to_elixir(_message) do
    base_payload = case (_message) do
  {:todocreated, todo} ->
    g = elem(_message, 1)
    todo = g
    %{:type => "todo_created", :todo => todo}
  {:todoupdated, todo} ->
    g = elem(_message, 1)
    todo = g
    %{:type => "todo_updated", :todo => todo}
  {:tododeleted, id} ->
    g = elem(_message, 1)
    id = g
    %{:type => "todo_deleted", :todo_id => id}
  {:bulkupdate, action} ->
    g = elem(_message, 1)
    action = g
    %{:type => "bulk_update", :action => bulk_action_to_string(action)}
  {:useronline, user_id} ->
    g = elem(_message, 1)
    user_id = g
    %{:type => "user_online", :user_id => user_id}
  {:useroffline, user_id} ->
    g = elem(_message, 1)
    user_id = g
    %{:type => "user_offline", :user_id => user_id}
  {:systemalert, message, level} ->
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
            {:some, g} ->
              g = elem(bulk_action, 1)
              action = g
              {:bulk_update, action}
            {:none} ->
              :none
          end
        else
          :none
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          alert_level = parse_alert_level(msg.level)
          case (alert_level) do
            {:some, g} ->
              g = elem(alert_level, 1)
              level = g
              {:system_alert, msg.message, level}
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
  defp bulk_action_to_string(_action) do
    case (_action) do
      {:completeall} ->
        "complete_all"
      {:deletecompleted} ->
        "delete_completed"
      {:setpriority, priority} ->
        g = elem(_action, 1)
        _priority = g
        "set_priority"
      {:addtag, tag} ->
        g = elem(_action, 1)
        _tag = g
        "add_tag"
      {:removetag, tag} ->
        g = elem(_action, 1)
        _tag = g
        "remove_tag"
    end
  end
  defp parse_bulk_action(action) do
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
  defp alert_level_to_string(_level) do
    case (_level) do
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
  defp parse_alert_level(level) do
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