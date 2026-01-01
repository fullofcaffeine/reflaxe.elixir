package server.pubsub;

import haxe.ds.Option;
import StringTools;
import server.types.Types.BulkOperationType;
import server.types.Types.AlertLevel;
import elixir.Atom;
import elixir.Tuple;
import phoenix.PubSubShim;
import server.types.Types.TodoPriority;
import elixir.types.Term;
import Type;

/**
 * Type-safe PubSub bridge for the todo-app.
 * Converts typed Haxe enums to Phoenix.PubSub calls.
 */
@:native("TodoApp.TodoPubSub")
class TodoPubSub {
    /**
     * Subscribe to a topic.
     */
    public static function subscribe(topic: TodoPubSubTopic): haxe.functional.Result<Void, String> {
        var topicStr = topicToString(topic);
        var pubsub = pubsubModule();
        // Phoenix.PubSub.subscribe/2 accepts the PubSub server module and topic
        PubSubShim.subscribe(pubsub, topicStr);
        return Ok(null);
    }

    /**
     * Broadcast a message to a topic.
     */
    public static function broadcast(topic: TodoPubSubTopic, msg: TodoPubSubMessage): haxe.functional.Result<Void, String> {
        var topicStr = topicToString(topic);
        var msgTuple = messageToElixir(msg);
        var pubsub = pubsubModule();
        PubSubShim.broadcast(pubsub, topicStr, msgTuple);
        return Ok(null);
    }

    /**
     * Parse an incoming message back to the enum type.
     */
    public static function parseMessage(msg: Term): Option<TodoPubSubMessage> {
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
     */
    public static function messageToElixir(msg: TodoPubSubMessage): Term {
        var params = Type.enumParameters(msg);
        return switch (Type.enumConstructor(msg)) {
            case "TodoCreated":
                Tuple.make2(todoCreatedAtom(), cast params[0]);
            case "TodoUpdated":
                Tuple.make2(todoUpdatedAtom(), cast params[0]);
            case "TodoDeleted":
                Tuple.make2(todoDeletedAtom(), cast params[0]);
            case "BulkUpdate":
                Tuple.make2(bulkUpdateAtom(), bulkActionToString(cast params[0]));
            case "UserOnline":
                Tuple.make2(userOnlineAtom(), cast params[0]);
            case "UserOffline":
                Tuple.make2(userOfflineAtom(), cast params[0]);
            case "UserProfileUpdated":
                Tuple.make2(userProfileUpdatedAtom(), cast params[0]);
            case "SystemAlert":
                systemAlertTuple(cast params[0], cast params[1]);
            case _: msg;
        };
    }

    /**
     * Parse an Elixir tuple message back to the enum.
     */
    public static function parseMessageImpl(msg: Term): Option<TodoPubSubMessage> {
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
            case "user_profile_updated": Some(UserProfileUpdated(cast Tuple.elem(msg, 1)));
            case "system_alert":
                Some(SystemAlert(cast Tuple.elem(msg, 1), parseAlertLevel(cast Tuple.elem(msg, 2))));
            default: None;
        };
    }

    @:keep
    public static function bulkActionToString(action: BulkOperationType): String {
        var params = Type.enumParameters(action);
        return switch (Type.enumConstructor(action)) {
            case "CompleteAll": "complete_all";
            case "DeleteCompleted": "delete_completed";
            case "SetPriority":
                var priorityValue: TodoPriority = cast params[0];
                var priorityLabel = switch (priorityValue) {
                    case Low: "low";
                    case Medium: "medium";
                    case High: "high";
                };
                "set_priority_" + priorityLabel;
            case "AddTag":
                var tagValue: String = cast params[0];
                "add_tag_" + tagValue;
            case "RemoveTag":
                var tagValue: String = cast params[0];
                "remove_tag_" + tagValue;
            case _: "complete_all";
        };
    }

    @:keep
    public static function alertLevelToString(level: AlertLevel): String {
        if (level == null) return "info";
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

    static inline function systemAlertTuple(alertMessage: String, alertLevelValue: AlertLevel): Term {
        var levelLabel = alertLevelToString(alertLevelValue);
        return Tuple.make3(systemAlertAtom(), alertMessage, levelLabel);
    }

    static inline function pubsubModule(): Term {
        // Module atoms are Elixir atoms like :"Elixir.TodoApp.PubSub"
        return Atom.fromString("Elixir.TodoApp.PubSub");
    }

    static inline function todoCreatedAtom(): Term return Atom.create("todo_created");
    static inline function todoUpdatedAtom(): Term return Atom.create("todo_updated");
    static inline function todoDeletedAtom(): Term return Atom.create("todo_deleted");
    static inline function bulkUpdateAtom(): Term return Atom.create("bulk_update");
    static inline function userOnlineAtom(): Term return Atom.create("user_online");
    static inline function userOfflineAtom(): Term return Atom.create("user_offline");
    static inline function userProfileUpdatedAtom(): Term return Atom.create("user_profile_updated");
    static inline function systemAlertAtom(): Term return Atom.create("system_alert");
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
    UserProfileUpdated(payload: UserProfileUpdatedPayload);
    SystemAlert(message: String, level: AlertLevel);
}

typedef UserProfileUpdatedPayload = {
    var user_id: Int;
    var name: String;
    var email: String;
    var bio: Null<String>;
}
