package server.pubsub;

import haxe.ds.Option;
import StringTools;
import server.types.Types.BulkOperationType;
import server.types.Types.AlertLevel;
import elixir.Atom;
import elixir.Tuple;
import phoenix.PubSubShim;
import server.types.Types.TodoPriority;
import Type;

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
        // Phoenix.PubSub.subscribe/2 accepts the PubSub server name and topic
        PubSubShim.subscribe("TodoApp.PubSub", topicStr);
        return Ok(null);
    }

    /**
     * Broadcast a message to a topic.
     */
    public static function broadcast(topic: TodoPubSubTopic, message: TodoPubSubMessage): haxe.functional.Result<Void, String> {
        var topicStr = topicToString(topic);
        var msgTuple = messageToElixir(message);
        PubSubShim.broadcast("TodoApp.PubSub", topicStr, msgTuple);
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
        var idx = Type.enumIndex(message);
        var params = Type.enumParameters(message);
        return switch (idx) {
            case 0: // TodoCreated(todo)
                Tuple.make2(Atom.create("todo_created"), params[0]);
            case 1: // TodoUpdated(todo)
                Tuple.make2(Atom.create("todo_updated"), params[0]);
            case 2: // TodoDeleted(id)
                Tuple.make2(Atom.create("todo_deleted"), params[0]);
            case 3: // BulkUpdate(action)
                Tuple.make2(Atom.create("bulk_update"), bulkActionToString(cast params[0]));
            case 4: // UserOnline(userId)
                Tuple.make2(Atom.create("user_online"), params[0]);
            case 5: // UserOffline(userId)
                Tuple.make2(Atom.create("user_offline"), params[0]);
            case _: // SystemAlert(message, level)
                var msg: String = cast params[0];
                var lvl: AlertLevel = cast params[1];
                Tuple.make3(Atom.create("system_alert"), msg, alertLevelToString(lvl));
        }
    }

    /**
     * Parse an Elixir tuple message back to the enum.
     */
    public static function parseMessageImpl(msg: Dynamic): Option<TodoPubSubMessage> {
        // Expect tuples shaped like {:tag, payload} or {:tag, payload, extra}
        var tagAtom = Tuple.elem(msg, 0);
        var tag = Atom.toString(tagAtom);
        return switch (tag) {
            case "todo_created": Some(TodoCreated(cast Tuple.elem(msg, 1)));
            case "todo_updated": Some(TodoUpdated(cast Tuple.elem(msg, 1)));
            case "todo_deleted": Some(TodoDeleted(cast Tuple.elem(msg, 1)));
            case "bulk_update": Some(BulkUpdate(parseBulkAction(cast Tuple.elem(msg, 1))));
            case "user_online": Some(UserOnline(cast Tuple.elem(msg, 1)));
            case "user_offline": Some(UserOffline(cast Tuple.elem(msg, 1)));
            case "system_alert":
                Some(SystemAlert(cast Tuple.elem(msg, 1), parseAlertLevel(cast Tuple.elem(msg, 2))));
            default: None;
        };
    }

    public static function bulkActionToString(action: BulkOperationType): String {
        return switch (Type.enumIndex(action)) {
            case 0: "complete_all";
            case 1: "delete_completed";
            case 2:
                var priority: TodoPriority = cast Type.enumParameters(action)[0];
                var priorityLabel = switch (priority) {
                    case Low: "low";
                    case Medium: "medium";
                    case High: "high";
                };
                "set_priority_" + priorityLabel;
            case 3:
                var tagValue: String = cast Type.enumParameters(action)[0];
                "add_tag_" + tagValue;
            case 4:
                var tagValue: String = cast Type.enumParameters(action)[0];
                "remove_tag_" + tagValue;
            case _: "complete_all";
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
        return if (str == "complete_all") {
            CompleteAll;
        } else if (str == "delete_completed") {
            DeleteCompleted;
        } else if (str != null && StringTools.startsWith(str, "set_priority_")) {
            var suffix = StringTools.replace(str, "set_priority_", "");
            switch (suffix) {
                case "low": SetPriority(Low);
                case "medium": SetPriority(Medium);
                case "high": SetPriority(High);
                case _: CompleteAll;
            };
        } else if (str != null && StringTools.startsWith(str, "add_tag_")) {
            var suffix = StringTools.replace(str, "add_tag_", "");
            AddTag(suffix);
        } else if (str != null && StringTools.startsWith(str, "remove_tag_")) {
            var suffix = StringTools.replace(str, "remove_tag_", "");
            RemoveTag(suffix);
        } else {
            CompleteAll;
        };
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
