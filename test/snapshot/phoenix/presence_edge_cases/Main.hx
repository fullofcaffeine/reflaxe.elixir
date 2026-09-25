package;

import phoenix.PresenceBehavior;
import phoenix.PresenceTopic;
import phoenix.PresenceKey;

/** Branching calls retain the declared tracker and thread the original socket. */
@:presence
@:native("MyAppWeb.ConditionalPresence")
class ConditionalPresence implements PresenceBehavior {
	public static function trackConditionally<T>(socket:T, userId:String, isAdmin:Bool):T {
		if (isAdmin)
			return trackWithSocket(socket, PresenceTopic.of("conditional"), PresenceKey.of(userId), {role: "admin"});
		return trackWithSocket(socket, PresenceTopic.of("conditional"), PresenceKey.of(userId), {role: "user"});
	}

	public static function trackInSwitch<T>(socket:T, userId:String, userType:String):T {
		return switch userType {
			case "admin": trackWithSocket(socket, "switch", userId, {role: "admin", permissions: "all"});
			case "moderator": trackWithSocket(socket, "switch", userId, {role: "mod", permissions: "some"});
			case _: trackWithSocket(socket, "switch", userId, {role: "user", permissions: "basic"});
		};
	}
}

typedef User = {
	final id:String;
	final firstName:String;
	final lastName:String;
	final score:Int;
}

/** Expressions and nested callbacks retain their tracker, values and effects. */
@:presence
@:native("MyAppWeb.ComplexPresence")
class ComplexPresence implements PresenceBehavior {
	public static function trackWithComputation<T>(socket:T, user:User):T
		return trackWithSocket(socket, "computed", user.id + "_key", {
			name: user.firstName + " " + user.lastName,
			computed: user.score > 100 ? "expert" : "novice"
		});

	public static function trackNested<T>(socket:T, users:Array<User>):Array<T>
		return users.map(user -> trackWithSocket(socket, "nested", user.id, {status: "online"}));
}

/** A web caller chooses an explicit tracker; its name does not grant Presence ownership. */
@:keep
@:native("MyAppWeb.PresenceCaller")
class PresenceCaller {
	public static function register<T>(socket:T, userId:String):T
		return ConditionalPresence.trackConditionally(socket, userId, true);
}

/** Cross-module calls must not be redirected to this enclosing Presence module. */
@:presence
@:native("MyAppWeb.MixedUsage")
class MixedUsage implements PresenceBehavior {
	public static function localAndRemote<T>(socket:T, userId:String):T {
		socket = trackWithSocket(socket, "local", userId, {local: true});
		return ConditionalPresence.trackConditionally(socket, userId, false);
	}
}

class Main {
	static function main() {}
}
