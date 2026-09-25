package;

import phoenix.PresenceBehavior;
import phoenix.PresenceTopic;
import phoenix.PresenceKey;
import phoenix.Presence.PresenceEntry;

/** A declared tracker owns every operation; native names are not inferred from callers. */
@:presence
@:native("MyAppWeb.ChatPresence")
class ChatPresence implements PresenceBehavior {
	public static function trackUser<T>(socket:T, userId:String, meta:UserMeta):T
		return trackWithSocket(socket, PresenceTopic.of("users"), PresenceKey.of(userId), meta);

	public static function updateUser<T>(socket:T, userId:String, meta:UserMeta):T
		return updateWithSocket(socket, PresenceTopic.of("users"), PresenceKey.of(userId), meta);

	public static function untrackUser<T>(socket:T, userId:String):T
		return untrackWithSocket(socket, PresenceTopic.of("users"), PresenceKey.of(userId));

	public static function listUsers():Map<String, PresenceEntry<UserMeta>>
		return list(PresenceTopic.of("users"));

	public static function getUserByKey(key:PresenceKey):Null<PresenceEntry<UserMeta>>
		return getByKey(PresenceTopic.of("users"), key);
}

typedef UserMeta = {final status:String;}

/** Ordinary callers select the same declared tracker through typed Haxe calls. */
@:keep
@:native("MyAppWeb.NormalModule")
class NormalModule {
	public static function trackFromOutside<T>(socket:T, userId:String):T
		return ChatPresence.trackUser(socket, userId, {status: "outside"});

	public static function updateFromOutside<T>(socket:T, userId:String):T
		return ChatPresence.updateUser(socket, userId, {status: "updated"});

	public static function listFromOutside():Map<String, PresenceEntry<UserMeta>>
		return ChatPresence.listUsers();
}

/** A second tracker preserves its independent native name and metadata expressions. */
@:presence
@:native("MyAppWeb.SpecialPresence")
class SpecialPresence implements PresenceBehavior {
	public static function trackSpecial<T>(socket:T, key:PresenceKey, meta:UserMeta):T
		return trackWithSocket(socket, PresenceTopic.of("special"), key, meta);

	public static function trackWithStringOp<T>(socket:T, userId:String):T {
		final key = userId.length > 0 ? userId : "anonymous";
		return trackSpecial(socket, key, {status: "special"});
	}
}

class Main {
	static function main() {}
}
