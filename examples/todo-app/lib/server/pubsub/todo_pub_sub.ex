defmodule TodoPubSub do
  def subscribe() do
    fn topic -> {:unknown, topic, TodoPubSub.topicToString} end
  end
  def broadcast() do
    fn topic, message -> {:unknown, topic, message, TodoPubSub.topicToString, TodoPubSub.messageToElixir} end
  end
  def parseMessage() do
    fn msg -> {:unknown, msg, TodoPubSub.parseMessageImpl} end
  end
  defp topicToString() do
    fn topic -> case (topic.elem(0)) do
  0 ->
    "todo:updates"
  1 ->
    "user:activity"
  2 ->
    "system:notifications"
end end
  end
  defp messageToElixir() do
    fn message -> base_payload = case (message.elem(0)) do
  0 ->
    g = message.elem(1)
    todo = g
    %{:type => "todo_created", :todo => todo}
  1 ->
    g = message.elem(1)
    todo = g
    %{:type => "todo_updated", :todo => todo}
  2 ->
    g = message.elem(1)
    id = g
    %{:type => "todo_deleted", :todo_id => id}
  3 ->
    g = message.elem(1)
    action = g
    %{:type => "bulk_update", :action => TodoPubSub.bulk_action_to_string(action)}
  4 ->
    g = message.elem(1)
    user_id = g
    %{:type => "user_online", :user_id => user_id}
  5 ->
    g = message.elem(1)
    user_id = g
    %{:type => "user_offline", :user_id => user_id}
  6 ->
    g = message.elem(1)
    g_1 = message.elem(2)
    message = g
    level = g1
    %{:type => "system_alert", :message => message, :level => TodoPubSub.alert_level_to_string(level)}
end
SafePubSub.add_timestamp(base_payload) end
  end
  defp parseMessageImpl() do
    fn msg -> if (not SafePubSub.is_valid_message(msg)) do
  Log.trace(SafePubSub.create_malformed_message_error(msg), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 188, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
  :None
end
g = msg.type
case (g) do
  "bulk_update" ->
    if (msg.action != nil) do
      bulk_action = {:unknown, msg.action}
      case (bulk_action.elem(0)) do
        0 ->
          g = bulk_action.elem(1)
          action = g
          {:Some, {:BulkUpdate, action}}
        1 ->
          :None
      end
    else
      :None
    end
  "system_alert" ->
    if (msg.message != nil && msg.level != nil) do
      alert_level = {:unknown, msg.level}
      case (alert_level.elem(0)) do
        0 ->
          g = alert_level.elem(1)
          level = g
          {:Some, {:SystemAlert, msg.message, level}}
        1 ->
          :None
      end
    else
      :None
    end
  "todo_created" ->
    if (msg.todo != nil) do
      {:Some, {:TodoCreated, msg.todo}}
    else
      :None
    end
  "todo_deleted" ->
    if (msg.todo_id != nil) do
      {:Some, {:TodoDeleted, msg.todo_id}}
    else
      :None
    end
  "todo_updated" ->
    if (msg.todo != nil) do
      {:Some, {:TodoUpdated, msg.todo}}
    else
      :None
    end
  "user_offline" ->
    if (msg.user_id != nil) do
      {:Some, {:UserOffline, msg.user_id}}
    else
      :None
    end
  "user_online" ->
    if (msg.user_id != nil) do
      {:Some, {:UserOnline, msg.user_id}}
    else
      :None
    end
  _ ->
    Log.trace(SafePubSub.create_unknown_message_error(msg.type), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 220, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
    :None
end end
  end
  defp bulkActionToString() do
    fn action -> case (action.elem(0)) do
  0 ->
    "complete_all"
  1 ->
    "delete_completed"
  2 ->
    g = action.elem(1)
    priority = g
    "set_priority"
  3 ->
    g = action.elem(1)
    tag = g
    "add_tag"
  4 ->
    g = action.elem(1)
    tag = g
    "remove_tag"
end end
  end
  defp parseBulkAction() do
    fn action -> case (action) do
  "add_tag" ->
    {:Some, {:AddTag, ""}}
  "complete_all" ->
    {:Some, :CompleteAll}
  "delete_completed" ->
    {:Some, :DeleteCompleted}
  "remove_tag" ->
    {:Some, {:RemoveTag, ""}}
  "set_priority" ->
    {:Some, {:SetPriority, :Medium}}
  _ ->
    :None
end end
  end
  defp alertLevelToString() do
    fn level -> case (level.elem(0)) do
  0 ->
    "info"
  1 ->
    "warning"
  2 ->
    "error"
  3 ->
    "critical"
end end
  end
  defp parseAlertLevel() do
    fn level -> case (level) do
  "critical" ->
    {:Some, :Critical}
  "error" ->
    {:Some, :Error}
  "info" ->
    {:Some, :Info}
  "warning" ->
    {:Some, :Warning}
  _ ->
    :None
end end
  end
end