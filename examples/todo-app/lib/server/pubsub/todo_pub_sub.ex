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
    SafePubSub.subscribe_with_converter(topic, &TodoPubSub.topic_to_string/1)
  end

  @doc "Generated from Haxe broadcast"
  def broadcast(topic, message) do
    SafePubSub.broadcast_with_converters(topic, message, &TodoPubSub.topic_to_string/1, &TodoPubSub.message_to_elixir/1)
  end

  @doc "Generated from Haxe parseMessage"
  def parse_message(msg) do
    SafePubSub.parse_with_converter(msg, &TodoPubSub.parse_message_impl/1)
  end

  @doc "Generated from Haxe topicToString"
  def topic_to_string(topic) do
    temp_result = nil

    temp_result = nil

    case topic do
      :todo_updates -> "todo:updates"
      :user_activity -> "user:activity"
      :system_notifications -> "system:notifications"
    end

    temp_result
  end

  @doc "Generated from Haxe messageToElixir"
  def message_to_elixir(message) do
    temp_struct = nil

    temp_struct = nil

    case message do
      0 -> g_param_0 = elem(message, 1)
    todo = g_array
    temp_struct = %{"type" => "todo_created", "todo" => todo}
      1 -> g_param_0 = elem(message, 1)
    todo = g_array
    temp_struct = %{"type" => "todo_updated", "todo" => todo}
      2 -> id = elem(message, 1)
    temp_struct = %{"type" => "todo_deleted", "todo_id" => id}
      3 -> action = elem(message, 1)
    temp_struct = %{"type" => "bulk_update", "action" => TodoPubSub.bulk_action_to_string(action)}
      4 -> g_param_0 = elem(message, 1)
    user_id = g_array
    temp_struct = %{"type" => "user_online", "user_id" => user_id}
      5 -> g_param_0 = elem(message, 1)
    user_id = g_array
    temp_struct = %{"type" => "user_offline", "user_id" => user_id}
      6 -> g_param_0 = elem(message, 1)
    g_param_1 = elem(message, 2)
    message = g_array
    level = g_param_1
    temp_struct = %{"type" => "system_alert", "message" => message, "level" => TodoPubSub.alert_level_to_string(level)}
    end

    SafePubSub.add_timestamp(temp_struct)
  end

  @doc "Generated from Haxe parseMessageImpl"
  def parse_message_impl(msg) do
    temp_result = nil

    if (not SafePubSub.is_valid_message(msg)) do
      Log.trace(SafePubSub.create_malformed_message_error(msg), %{"fileName" => "src_haxe/server/pubsub/TodoPubSub.hx", "lineNumber" => 188, "className" => "server.pubsub.TodoPubSub", "methodName" => "parseMessageImpl"})
      :error
    else
      nil
    end

    g_array = msg.type
    case g_array do
      "bulk_update" -> if ((msg.action != nil)) do
      bulk_action = TodoPubSub.parse_bulk_action(msg.action)
      case bulk_action do
        0 -> action = elem(bulk_action, 1)
      temp_result = Option.some(TodoPubSubMessage.bulk_update(action))
        1 -> temp_result = :error
      end
    else
      temp_result = :error
    end
      "system_alert" -> if (((msg.message != nil) && (msg.level != nil))) do
      alert_level = TodoPubSub.parse_alert_level(msg.level)
      case alert_level do
        0 -> level = elem(alert_level, 1)
      temp_result = Option.some(TodoPubSubMessage.system_alert(msg.message, level))
        1 -> temp_result = :error
      end
    else
      temp_result = :error
    end
      "todo_created" -> if ((msg.todo != nil)), do: temp_result = Option.some(TodoPubSubMessage.todo_created(msg.todo)), else: temp_result = :error
      "todo_deleted" -> if ((msg.todo_id != nil)), do: temp_result = Option.some(TodoPubSubMessage.todo_deleted(msg.todo_id)), else: temp_result = :error
      "todo_updated" -> if ((msg.todo != nil)), do: temp_result = Option.some(TodoPubSubMessage.todo_updated(msg.todo)), else: temp_result = :error
      "user_offline" -> if ((msg.user_id != nil)), do: temp_result = Option.some(TodoPubSubMessage.user_offline(msg.user_id)), else: temp_result = :error
      "user_online" -> if ((msg.user_id != nil)), do: temp_result = Option.some(TodoPubSubMessage.user_online(msg.user_id)), else: temp_result = :error
      _ -> Log.trace(SafePubSub.create_unknown_message_error(msg.type), %{"fileName" => "src_haxe/server/pubsub/TodoPubSub.hx", "lineNumber" => 220, "className" => "server.pubsub.TodoPubSub", "methodName" => "parseMessageImpl"})
    temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe bulkActionToString"
  def bulk_action_to_string(action) do
    temp_result = nil

    case action do
      0 -> temp_result = "complete_all"
      1 -> temp_result = "delete_completed"
      2 -> _priority = elem(action, 1)
    temp_result = "set_priority"
      3 -> g_param_0 = elem(action, 1)
    tag = g_array
    temp_result = "add_tag"
      4 -> g_param_0 = elem(action, 1)
    tag = g_array
    temp_result = "remove_tag"
    end

    temp_result
  end

  @doc "Generated from Haxe parseBulkAction"
  def parse_bulk_action(action) do
    temp_result = nil

    case action do
      "add_tag" -> Option.some(BulkOperationType.add_tag(""))
      "complete_all" -> Option.some(:complete_all)
      "delete_completed" -> Option.some(:delete_completed)
      "remove_tag" -> Option.some(BulkOperationType.remove_tag(""))
      "set_priority" -> Option.some(BulkOperationType.set_priority(:medium))
      _ -> :error
    end

    temp_result
  end

  @doc "Generated from Haxe alertLevelToString"
  def alert_level_to_string(level) do
    temp_result = nil

    case level do
      :info -> "info"
      :warning -> "warning"
      :error -> "error"
      :critical -> "critical"
    end

    temp_result
  end

  @doc "Generated from Haxe parseAlertLevel"
  def parse_alert_level(level) do
    temp_result = nil

    case level do
      "critical" -> Option.some(:critical)
      "error" -> Option.some(:error)
      "info" -> Option.some(:info)
      "warning" -> Option.some(:warning)
      _ -> :error
    end

    temp_result
  end

end
