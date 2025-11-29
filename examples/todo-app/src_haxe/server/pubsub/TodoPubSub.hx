package server.pubsub;

import haxe.ds.Option;
import server.types.Types.BulkOperationType;
import server.types.Types.AlertLevel;

/**
 * Extern for typed PubSub bridge.
 * Implemented at runtime as TodoAppWeb.PubSub (see lib/reflaxe_runtime/server/pubsub/todo_pub_sub.ex).
 */
@:native("TodoAppWeb.TodoPubSub")
@:nativeGen
extern class TodoPubSub {
    public static function subscribe(topic: TodoPubSubTopic): haxe.functional.Result<Void, String>;
    public static function broadcast(topic: TodoPubSubTopic, message: TodoPubSubMessage): haxe.functional.Result<Void, String>;
    public static function parseMessage(msg: Dynamic): Option<TodoPubSubMessage>;
    public static function topicToString(topic: TodoPubSubTopic): String;
    public static function messageToElixir(message: TodoPubSubMessage): Dynamic;
    public static function parseMessageImpl(msg: Dynamic): Option<TodoPubSubMessage>;
    public static function bulkActionToString(action: BulkOperationType): String;
    public static function alertLevelToString(level: AlertLevel): String;
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
    UserOnline(user_id: Int);
    UserOffline(user_id: Int);
    SystemAlert(message: String, level: AlertLevel);
}
