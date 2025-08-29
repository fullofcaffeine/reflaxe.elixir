defmodule TodoPubSub do
  @moduledoc """
    TodoPubSub module generated from Haxe

     * Todo-app specific SafePubSub wrapper with complete type safety
     *
     * This class provides a convenient API for the todo application while
     * using the framework's SafePubSub infrastructure underneath.
  """

  # Static functions
  @doc "Generated from Haxe subscribe"
  def subscribe(topic) do
    SafePubSub.subscribe_with_converter(topic, TodoPubSub.topicToString)
  end

  @doc "Generated from Haxe broadcast"
  def broadcast(topic, message) do
    SafePubSub.broadcast_with_converters(topic, message, TodoPubSub.topicToString, TodoPubSub.messageToElixir)
  end

  @doc "Generated from Haxe parseMessage"
  def parse_message(msg) do
    SafePubSub.parse_with_converter(msg, TodoPubSub.parseMessageImpl)
  end

  @doc "Generated from Haxe topicToString"
  def topic_to_string(topic) do
    temp_result = nil

    temp_result = nil
    case (topic.elem(0)) do
      0 ->
        temp_result = "todo:updates"
      1 ->
        temp_result = "user:activity"
      2 ->
        temp_result = "system:notifications"
    end
    temp_result
  end

  @doc "Generated from Haxe messageToElixir"
  def message_to_elixir(message) do
    temp_struct = nil

    temp_struct = nil
    case (message.elem(0)) do
      0 ->
        g = message.elem(1)
        todo = g
        temp_struct = %{:type => "todo_created", :todo => todo}
      1 ->
        g = message.elem(1)
        todo = g
        temp_struct = %{:type => "todo_updated", :todo => todo}
      2 ->
        g = message.elem(1)
        id = g
        temp_struct = %{:type => "todo_deleted", :todo_id => id}
      3 ->
        g = message.elem(1)
        action = g
        temp_struct = %{:type => "bulk_update", :action => TodoPubSub.bulk_action_to_string(action)}
      4 ->
        g = message.elem(1)
        user_id = g
        temp_struct = %{:type => "user_online", :user_id => user_id}
      5 ->
        g = message.elem(1)
        user_id = g
        temp_struct = %{:type => "user_offline", :user_id => user_id}
      6 ->
        g = message.elem(1)
        g_1 = message.elem(2)
        message_2 = g
        level = g_1
        temp_struct = %{:type => "system_alert", :message => message, :level => TodoPubSub.alert_level_to_string(level)}
    end
    SafePubSub.add_timestamp(temp_struct)
  end

  @doc "Generated from Haxe parseMessageImpl"
  def parse_message_impl(msg) do
    temp_result = nil

    if (not SafePubSub.is_valid_message(msg)) do
      Log.trace(SafePubSub.create_malformed_message_error(msg), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 188, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
      :None
    end
    temp_result = nil
    g = msg.type
    case (g) do
      "bulk_update" ->
        if (msg.action != nil) do
          bulk_action = TodoPubSub.parse_bulk_action(msg.action)
          case (bulk_action.elem(0)) do
            0 ->
              g_2 = bulk_action.elem(1)
              action = g_2
              temp_result = {:Some, {:BulkUpdate, action}}
            1 ->
              temp_result = :None
          end
        else
          temp_result = :None
        end
      "system_alert" ->
        if (msg.message != nil && msg.level != nil) do
          alert_level = TodoPubSub.parse_alert_level(msg.level)
          case (alert_level.elem(0)) do
            0 ->
              g_2 = alert_level.elem(1)
              level = g_2
              temp_result = {:Some, {:SystemAlert, msg.message, level}}
            1 ->
              temp_result = :None
          end
        else
          temp_result = :None
        end
      "todo_created" ->
        if (msg.todo != nil) do
          temp_result = {:Some, {:TodoCreated, msg.todo}}
        else
          temp_result = :None
        end
      "todo_deleted" ->
        if (msg.todo_id != nil) do
          temp_result = {:Some, {:TodoDeleted, msg.todo_id}}
        else
          temp_result = :None
        end
      "todo_updated" ->
        if (msg.todo != nil) do
          temp_result = {:Some, {:TodoUpdated, msg.todo}}
        else
          temp_result = :None
        end
      "user_offline" ->
        if (msg.user_id != nil) do
          temp_result = {:Some, {:UserOffline, msg.user_id}}
        else
          temp_result = :None
        end
      "user_online" ->
        if (msg.user_id != nil) do
          temp_result = {:Some, {:UserOnline, msg.user_id}}
        else
          temp_result = :None
        end
      _ ->
        Log.trace(SafePubSub.create_unknown_message_error(msg.type), %{:fileName => "src_haxe/server/pubsub/TodoPubSub.hx", :lineNumber => 220, :className => "server.pubsub.TodoPubSub", :methodName => "parseMessageImpl"})
        temp_result = :None
    end
    temp_result
  end

  @doc "Generated from Haxe bulkActionToString"
  def bulk_action_to_string(action) do
    temp_result = nil

    temp_result = nil
    case (action.elem(0)) do
      0 ->
        temp_result = "complete_all"
      1 ->
        temp_result = "delete_completed"
      2 ->
        g = action.elem(1)
        priority = g
        temp_result = "set_priority"
      3 ->
        g = action.elem(1)
        tag = g
        temp_result = "add_tag"
      4 ->
        g = action.elem(1)
        tag = g
        temp_result = "remove_tag"
    end
    temp_result
  end

  @doc "Generated from Haxe parseBulkAction"
  def parse_bulk_action(action) do
    temp_result = nil

    temp_result = nil
    case (action) do
      "add_tag" ->
        temp_result = {:Some, {:AddTag, ""}}
      "complete_all" ->
        temp_result = {:Some, :CompleteAll}
      "delete_completed" ->
        temp_result = {:Some, :DeleteCompleted}
      "remove_tag" ->
        temp_result = {:Some, {:RemoveTag, ""}}
      "set_priority" ->
        temp_result = {:Some, {:SetPriority, :Medium}}
      _ ->
        temp_result = :None
    end
    temp_result
  end

  @doc "Generated from Haxe alertLevelToString"
  def alert_level_to_string(level) do
    temp_result = nil

    temp_result = nil
    case (level.elem(0)) do
      0 ->
        temp_result = "info"
      1 ->
        temp_result = "warning"
      2 ->
        temp_result = "error"
      3 ->
        temp_result = "critical"
    end
    temp_result
  end

  @doc "Generated from Haxe parseAlertLevel"
  def parse_alert_level(level) do
    temp_result = nil

    temp_result = nil
    case (level) do
      "critical" ->
        temp_result = {:Some, :Critical}
      "error" ->
        temp_result = {:Some, :Error}
      "info" ->
        temp_result = {:Some, :Info}
      "warning" ->
        temp_result = {:Some, :Warning}
      _ ->
        temp_result = :None
    end
    temp_result
  end

end
