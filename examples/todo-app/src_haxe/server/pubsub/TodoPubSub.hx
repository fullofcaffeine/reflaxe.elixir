package server.pubsub;

import haxe.ds.Option;
import StringTools;
import server.types.Types.BulkOperationType;
import server.types.Types.AlertLevel;
import elixir.Atom;
import elixir.Kernel;
import elixir.Tuple;
import phoenix.Params;
import phoenix.PubSub;
import server.types.Types.TodoPriority;
import elixir.types.Term;

/**
 * Type-safe PubSub bridge for the todo-app.
 * Converts typed Haxe enums to Phoenix.PubSub calls.
 */
class TodoPubSub {
	/**
	 * Subscribe to a topic.
	 */
	public static function subscribe(topic:TodoPubSubTopic, ?organizationId:Int):haxe.functional.Result<Void, String> {
		var topicStr = topicToString(topic, organizationId);
		var pubsub = pubsubModule();
		// Phoenix.PubSub.subscribe/2 accepts the PubSub server module and topic
		PubSub.subscribe(pubsub, topicStr);
		return Ok(null);
	}

	/**
	 * Broadcast a message to a topic.
	 */
	public static function broadcast(topic:TodoPubSubTopic, msg:TodoPubSubMessage, ?organizationId:Int):haxe.functional.Result<Void, String> {
		var topicStr = topicToString(topic, organizationId);
		var msgTuple = messageToElixir(msg);
		var pubsub = pubsubModule();
		PubSub.broadcastFrom(pubsub, Kernel.self(), topicStr, msgTuple);
		return Ok(null);
	}

	/**
	 * Parse an incoming message back to the enum type.
	 */
	public static function parseMessage(msg:Term):Option<TodoPubSubMessage> {
		return parseMessageImpl(msg);
	}

	/**
	 * Convert topic enum to string for Phoenix.PubSub.
	 */
	public static function topicToString(topic:TodoPubSubTopic, ?organizationId:Int):String {
		var base = switch (topic) {
			case TodoUpdates: "todo_updates";
			case UserActivity: "user_activity";
			case SystemNotifications: "system_notifications";
		};
		return organizationId != null ? ("org:" + Std.string(organizationId) + ":" + base) : base;
	}

	/**
	 * Convert message enum to Elixir tuple format.
	 */
	public static function messageToElixir(msg:TodoPubSubMessage):Term {
		var todoCreated = todoCreatedAtom();
		var todoUpdated = todoUpdatedAtom();
		var todoDeleted = todoDeletedAtom();
		var bulkUpdate = bulkUpdateAtom();
		var userOnline = userOnlineAtom();
		var userOffline = userOfflineAtom();
		var userProfileUpdated = userProfileUpdatedAtom();
		return switch (msg) {
			case TodoCreated(todo):
				Tuple.make2(todoCreated, todo);
			case TodoUpdated(todo):
				Tuple.make2(todoUpdated, todo);
			case TodoDeleted(id):
				Tuple.make2(todoDeleted, id);
			case BulkUpdate(action):
				Tuple.make2(bulkUpdate, bulkActionToString(action));
			case UserOnline(userId):
				Tuple.make2(userOnline, userId);
			case UserOffline(userId):
				Tuple.make2(userOffline, userId);
			case UserProfileUpdated(payload):
				Tuple.make2(userProfileUpdated, payload);
			case SystemAlert(message, level):
				systemAlertTuple(message, level);
		};
	}

	/**
	 * Parse an Elixir tuple message back to the enum.
	 */
	public static function parseMessageImpl(msg:Term):Option<TodoPubSubMessage> {
		// Expect tuples shaped like {:tag, payload} or {:tag, payload, extra}
		var tagAtom = Tuple.elem(msg, 0);
		var tag = Atom.toString(tagAtom);
		return switch (tag) {
			case "todo_created":
				var payload = Tuple.elem(msg, 1);
				Some(TodoCreated(todoPayload(payload)));
			case "todo_updated":
				var payload = Tuple.elem(msg, 1);
				Some(TodoUpdated(todoPayload(payload)));
			case "todo_deleted":
				var payload = Tuple.elem(msg, 1);
				switch (intPayload(payload)) {
					case Some(id): Some(TodoDeleted(id));
					case None: None;
				}
			case "bulk_update":
				var payload = Tuple.elem(msg, 1);
				Some(BulkUpdate(parseBulkAction(Params.stringFromTermDefault(payload, ""))));
			case "user_online":
				var payload = Tuple.elem(msg, 1);
				switch (intPayload(payload)) {
					case Some(userId): Some(UserOnline(userId));
					case None: None;
				}
			case "user_offline":
				var payload = Tuple.elem(msg, 1);
				switch (intPayload(payload)) {
					case Some(userId): Some(UserOffline(userId));
					case None: None;
				}
			case "user_profile_updated":
				var payload = Tuple.elem(msg, 1);
				Some(UserProfileUpdated(profilePayload(payload)));
			case "system_alert":
				var message = Params.stringFromTermDefault(Tuple.elem(msg, 1), "");
				var level = Params.stringFromTermDefault(Tuple.elem(msg, 2), "");
				Some(SystemAlert(message, parseAlertLevel(level)));
			default: None;
		};
	}

	// @:keep: these enum/string codec helpers are used from indirect PubSub serialization paths, so DCE should not prune them.

	@:keep
	public static function bulkActionToString(action:BulkOperationType):String {
		return switch (action) {
			case CompleteAll: "complete_all";
			case DeleteCompleted: "delete_completed";
			case SetPriority(priorityValue):
				var priorityLabel = switch (priorityValue) {
					case Low: "low";
					case Medium: "medium";
					case High: "high";
				};
				"set_priority_" + priorityLabel;
			case AddTag(tagValue):
				"add_tag_" + tagValue;
			case RemoveTag(tagValue):
				"remove_tag_" + tagValue;
		};
	}

	@:keep
	public static function alertLevelToString(level:AlertLevel):String {
		if (level == null)
			return "info";
		return switch (level) {
			case Info: "info";
			case Warning: "warning";
			case Error: "error";
			case Critical: "critical";
		};
	}

	public static function parseBulkAction(str:String):BulkOperationType {
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

	public static function parseAlertLevel(str:String):AlertLevel {
		return switch (str) {
			case "info": Info;
			case "warning": Warning;
			case "error": Error;
			case "critical": Critical;
			default: Info;
		};
	}

	static inline function systemAlertTuple(alertMessage:String, alertLevelValue:AlertLevel):Term {
		var levelLabel = alertLevelToString(alertLevelValue);
		return Tuple.make3(systemAlertAtom(), alertMessage, levelLabel);
	}

	static function todoPayload(value:Term):server.schemas.Todo {
		return cast value;
	}

	static function profilePayload(value:Term):UserProfileUpdatedPayload {
		return cast value;
	}

	static function intPayload(value:Term):Option<Int> {
		var decoded = Params.intFromTerm(value);
		return decoded != null ? Some(decoded) : None;
	}

	static inline function pubsubModule():Term {
		// Module atoms are Elixir atoms like :"Elixir.TodoApp.PubSub"
		return Atom.fromString("Elixir.TodoApp.PubSub");
	}

	static inline function todoCreatedAtom():Term
		return Atom.create("todo_created");

	static inline function todoUpdatedAtom():Term
		return Atom.create("todo_updated");

	static inline function todoDeletedAtom():Term
		return Atom.create("todo_deleted");

	static inline function bulkUpdateAtom():Term
		return Atom.create("bulk_update");

	static inline function userOnlineAtom():Term
		return Atom.create("user_online");

	static inline function userOfflineAtom():Term
		return Atom.create("user_offline");

	static inline function userProfileUpdatedAtom():Term
		return Atom.create("user_profile_updated");

	static inline function systemAlertAtom():Term
		return Atom.create("system_alert");
}

enum TodoPubSubTopic {
	TodoUpdates;
	UserActivity;
	SystemNotifications;
}

enum TodoPubSubMessage {
	TodoCreated(todo:server.schemas.Todo);
	TodoUpdated(todo:server.schemas.Todo);
	TodoDeleted(id:Int);
	BulkUpdate(action:BulkOperationType);
	UserOnline(userId:Int);
	UserOffline(userId:Int);
	UserProfileUpdated(payload:UserProfileUpdatedPayload);
	SystemAlert(message:String, level:AlertLevel);
}

typedef UserProfileUpdatedPayload = {
	var user_id:Int;
	var name:String;
	var email:String;
	var bio:Null<String>;
}
