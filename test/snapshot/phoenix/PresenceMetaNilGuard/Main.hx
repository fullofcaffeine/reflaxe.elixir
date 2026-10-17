package;

import phoenix.Presence;

/**
 * A Presence side effect does not assign a local metadata value.
 *
 * These syntax snapshots preserve field reads and explicit reassignment.
 * The first two functions deliberately dereference missing metadata: generated
 * code must not invent an empty map or silently turn invalid access into null.
 * Valid-record behavior is executed by regression/nullable_record_guard.
 */
typedef Meta = {
	var onlineAt:Float;
	var userName:String;
}

class Main {
	static function main() {}

	// A one-line guard must not replace the value after the Presence call.
	public static function needsCoalesceOneLiner(socket:Dynamic, key:String):String {
		var currentMeta:Null<Meta> = maybeGetMeta();
		if (currentMeta == null)
			Presence.track(socket, key, cast {});
		var name = currentMeta.userName;
		return name;
	}

	// Braces do not authorize implicit replacement either.
	public static function needsCoalesceDoEnd(socket:Dynamic, key:String):Float {
		var currentMeta:Null<Meta> = maybeGetMeta();
		if (currentMeta == null) {
			Presence.track(socket, key, cast {});
		}
		var ts = currentMeta.onlineAt;
		return ts;
	}

	// Only an explicit assignment changes the local metadata.
	public static function negativeReassignPreventsInjection(socket:Dynamic, key:String):Float {
		var currentMeta:Null<Meta> = maybeGetMeta();
		if (currentMeta == null)
			Presence.track(socket, key, cast {});
		currentMeta = {onlineAt: 0.0, userName: "x"};
		var ts = currentMeta.onlineAt;
		return ts;
	}

	// A side-effect-only path retains its explicit return value.
	public static function negativeNoFieldAccess(socket:Dynamic, key:String):Int {
		var currentMeta:Null<Meta> = maybeGetMeta();
		if (currentMeta == null)
			Presence.track(socket, key, cast {});
		return 0;
	}

	static function maybeGetMeta():Null<Meta> {
		return null; // simulate absence
	}
}
