package phoenix_hx_todo_hx.contexts;

import StringTools;
import ecto.Changeset;
import ecto.SchemaStruct;
import ecto.TypedQuery;
import elixir.ElixirEnum;
import elixir.types.Term;
import haxe.functional.Result;
import phoenix_hx_todo_hx.data.ChatMessage;
import phoenix_hx_todo_hx.data.User;
import phoenix_hx_todo_hx.infrastructure.Repo;
import phoenix_hx_todo_hx.live.AppLiveTypes.ChatMessageItem;

/**
 * ChatMessages context.
 *
 * WHAT
 * - Owns room-note persistence for the RailsHx chat panel port.
 *
 * WHY
 * - Phoenix code keeps writes in contexts and uses PubSub as a realtime signal.
 *   The LiveView refreshes from Ecto instead of accepting client-owned state.
 */
@:native("PhoenixHxTodo.ChatMessages")
class ChatMessages {
	static inline final maxRecentMessages = 6;

	public static function listRecent():Array<ChatMessage> {
		var query = TypedQuery.from(ChatMessage);
		var messages:Array<ChatMessage> = Repo.all(query);
		messages.sort((left, right) -> right.id - left.id);
		return ElixirEnum.take(messages, maxRecentMessages);
	}

	public static function createForUser(user:User, body:String):Result<ChatMessage, Changeset<ChatMessage, Term>> {
		var trimmedBody = StringTools.trim(body);
		var data = SchemaStruct.empty(ChatMessage);
		var params:Term = {body: trimmedBody, userId: user.id};
		return Repo.insert(ChatMessage.changeset(data, params));
	}

	public static function createForUserOk(user:User, body:String):Bool {
		return switch (createForUser(user, body)) {
			case Ok(_): true;
			case Error(_): false;
		};
	}

	public static function viewItems():Array<ChatMessageItem> {
		return listRecent().map(toItem);
	}

	static function toItem(message:ChatMessage):ChatMessageItem {
		var user = Accounts.getUser(message.userId);
		var owner = user != null ? User.displayName(user) : "Unknown user";
		return {
			id: message.id,
			body: message.body,
			owner: owner,
			row_class: "chat-message"
		};
	}
}
