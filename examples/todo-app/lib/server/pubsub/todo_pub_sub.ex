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

    case (case topic do :todo_updates -> 0; :user_activity -> 1; :system_notifications -> 2; _ -> -1 end) do
      0 -> "todo:updates"
      1 -> "user:activity"
      2 -> "system:notifications"
    end

    temp_result
  end

  @doc "Generated from Haxe messageToElixir"
  def message_to_elixir(message) do
    temp_struct = nil

    temp_struct = nil

    case (case message do :todo_created -> 0; :todo_updated -> 1; :todo_deleted -> 2; :bulk_update -> 3; :user_online -> 4; :user_offline -> 5; :system_alert -> 6; _ -> -1 end) do
      {0, todo} -> g_array = elem(message, 1)
    temp_struct = %{"type" => "todo_created", "todo" => todo}
      {1, todo} -> g_array = elem(message, 1)
    temp_struct = %{"type" => "todo_updated", "todo" => todo}
      {2, id} -> g_array = elem(message, 1)
    temp_struct = %{"type" => "todo_deleted", "todo_id" => id}
      {3, action} -> g_array = elem(message, 1)
    temp_struct = %{"type" => "bulk_update", "action" => TodoPubSub.bulk_action_to_string(action)}
      {4, user_id} -> g_array = elem(message, 1)
    temp_struct = %{"type" => "user_online", "user_id" => user_id}
      {5, user_id} -> g_array = elem(message, 1)
    temp_struct = %{"type" => "user_offline", "user_id" => user_id}
      {6, message, level} -> g_array = elem(message, 1)
    g_array = elem(message, 2)
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
    case (g_array) do
      _ -> Log.trace(SafePubSub.create_unknown_message_error(msg.type), %{"fileName" => "src_haxe/server/pubsub/TodoPubSub.hx", "lineNumber" => 220, "className" => "server.pubsub.TodoPubSub", "methodName" => "parseMessageImpl"})
    temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe bulkActionToString"
  def bulk_action_to_string(action) do
    temp_result = nil

    case (case action do :complete_all -> 0; :delete_completed -> 1; :set_priority -> 2; :add_tag -> 3; :remove_tag -> 4; _ -> -1 end) do
      0 -> temp_result = "complete_all"
      1 -> temp_result = "delete_completed"
      {2, __priority} -> g_array = elem(action, 1)
    temp_result = "set_priority"
      {3, __tag} -> g_array = elem(action, 1)
    temp_result = "add_tag"
      {4, __tag} -> g_array = elem(action, 1)
    temp_result = "remove_tag"
    end

    temp_result
  end

  @doc "Generated from Haxe parseBulkAction"
  def parse_bulk_action(action) do
    temp_result = nil

    case (action) do
      _ -> :error
    end

    temp_result
  end

  @doc "Generated from Haxe alertLevelToString"
  def alert_level_to_string(level) do
    temp_result = nil

    case (case level do :info -> 0; :warning -> 1; :error -> 2; :critical -> 3; _ -> -1 end) do
      0 -> "info"
      1 -> "warning"
      2 -> "error"
      3 -> "critical"
    end

    temp_result
  end

  @doc "Generated from Haxe parseAlertLevel"
  def parse_alert_level(level) do
    temp_result = nil

    case (level) do
      _ -> :error
    end

    temp_result
  end

end
