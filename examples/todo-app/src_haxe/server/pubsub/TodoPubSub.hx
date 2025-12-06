package server.pubsub;

import haxe.ds.Option;
import server.types.Types.BulkOperationType;
import server.types.Types.AlertLevel;

/**
 * Type-safe PubSub bridge for the todo-app.
 * Converts typed Haxe enums to Phoenix.PubSub calls.
 */
class TodoPubSub {
    /**
     * Subscribe to a topic.
     */
    public static function subscribe(topic: TodoPubSubTopic): haxe.functional.Result<Void, String> {
        var topicStr = topicToString(topic);
        untyped __elixir__('Phoenix.PubSub.subscribe(TodoApp.PubSub, {0})', topicStr);
        return Ok(null);
    }

    /**
     * Broadcast a message to a topic.
     */
    public static function broadcast(topic: TodoPubSubTopic, message: TodoPubSubMessage): haxe.functional.Result<Void, String> {
        var topicStr = topicToString(topic);
        var msgTuple = messageToElixir(message);
        untyped __elixir__('Phoenix.PubSub.broadcast(TodoApp.PubSub, {0}, {1})', topicStr, msgTuple);
        return Ok(null);
    }

    /**
     * Parse an incoming message back to the enum type.
     */
    public static function parseMessage(msg: Dynamic): Option<TodoPubSubMessage> {
        return parseMessageImpl(msg);
    }

    /**
     * Convert topic enum to string for Phoenix.PubSub.
     */
    public static function topicToString(topic: TodoPubSubTopic): String {
        return switch (topic) {
            case TodoUpdates: "todo_updates";
            case UserActivity: "user_activity";
            case SystemNotifications: "system_notifications";
        };
    }

    /**
     * Convert message enum to Elixir tuple format.
     * Uses direct pattern matching to avoid variable name inconsistency issues.
     */
    public static function messageToElixir(message: TodoPubSubMessage): Dynamic {
        // Use direct Elixir case expression to avoid variable naming bugs
        return untyped __elixir__('
            case {0} do
              {:todo_created, todo} -> {:todo_created, todo}
              {:todo_updated, todo} -> {:todo_updated, todo}
              {:todo_deleted, id} -> {:todo_deleted, id}
              {:bulk_update, action} -> {:bulk_update, action}
              {:user_online, uid} -> {:user_online, uid}
              {:user_offline, uid} -> {:user_offline, uid}
              {:system_alert, msg, level} -> {:system_alert, msg, level}
            end
        ', message);
    }

    /**
     * Parse an Elixir tuple message back to the enum.
     */
    public static function parseMessageImpl(msg: Dynamic): Option<TodoPubSubMessage> {
        // Match the tuple patterns from Elixir
        var parsed = untyped __elixir__('
            case {0} do
              {:todo_created, todo} -> {:some, {:todo_created, todo}}
              {:todo_updated, todo} -> {:some, {:todo_updated, todo}}
              {:todo_deleted, id} -> {:some, {:todo_deleted, id}}
              {:bulk_update, action} -> {:some, {:bulk_update, action}}
              {:user_online, user_id} -> {:some, {:user_online, user_id}}
              {:user_offline, user_id} -> {:some, {:user_offline, user_id}}
              {:system_alert, message, level} -> {:some, {:system_alert, message, level}}
              _ -> :none
            end
        ', msg);

        if (parsed == untyped __elixir__(':none')) {
            return None;
        }

        // Extract the inner value
        var inner: Dynamic = untyped __elixir__('elem({0}, 1)', parsed);
        var tag: String = untyped __elixir__('elem({0}, 0) |> Atom.to_string()', inner);

        return switch (tag) {
            case "todo_created": Some(TodoCreated(untyped __elixir__('elem({0}, 1)', inner)));
            case "todo_updated": Some(TodoUpdated(untyped __elixir__('elem({0}, 1)', inner)));
            case "todo_deleted": Some(TodoDeleted(untyped __elixir__('elem({0}, 1)', inner)));
            case "bulk_update": Some(BulkUpdate(parseBulkAction(untyped __elixir__('elem({0}, 1)', inner))));
            case "user_online": Some(UserOnline(untyped __elixir__('elem({0}, 1)', inner)));
            case "user_offline": Some(UserOffline(untyped __elixir__('elem({0}, 1)', inner)));
            case "system_alert": Some(SystemAlert(untyped __elixir__('elem({0}, 1)', inner), parseAlertLevel(untyped __elixir__('elem({0}, 2)', inner))));
            default: None;
        };
    }

    public static function bulkActionToString(action: BulkOperationType): String {
        return switch (action) {
            case CompleteAll: "complete_all";
            case DeleteCompleted: "delete_completed";
            case SetPriority(p): 'set_priority_${p}';
            case AddTag(tag): 'add_tag_${tag}';
            case RemoveTag(tag): 'remove_tag_${tag}';
        };
    }

    public static function alertLevelToString(level: AlertLevel): String {
        return switch (level) {
            case Info: "info";
            case Warning: "warning";
            case Error: "error";
            case Critical: "critical";
        };
    }

    public static function parseBulkAction(str: String): BulkOperationType {
        // Simple cases
        if (str == "complete_all") return CompleteAll;
        if (str == "delete_completed") return DeleteCompleted;
        // Default fallback
        return CompleteAll;
    }

    public static function parseAlertLevel(str: String): AlertLevel {
        return switch (str) {
            case "info": Info;
            case "warning": Warning;
            case "error": Error;
            case "critical": Critical;
            default: Info;
        };
    }
}

enum TodoPubSubTopic {
    TodoUpdates;
    UserActivity;
    SystemNotifications;
}

enum TodoPubSubMessage {
    TodoCreated(todo: server.schemas.Todo);
    TodoUpdated(todo: server.schemas.Todo);
    TodoDeleted(id: Int);
    BulkUpdate(action: BulkOperationType);
    UserOnline(userId: Int);
    UserOffline(userId: Int);
    SystemAlert(message: String, level: AlertLevel);
}
