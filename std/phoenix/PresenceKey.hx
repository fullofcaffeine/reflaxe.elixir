package phoenix;

/**
 * Typed Phoenix Presence key token.
 *
 * Presence keys are still Elixir strings at runtime. This abstract gives Haxe
 * code a named type so app APIs can distinguish a presence key from unrelated
 * strings while keeping raw string callsites source-compatible.
 */
extern abstract PresenceKey(String) from String to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function of(value:String):PresenceKey {
		return new PresenceKey(value);
	}

	public inline function toString():String {
		return this;
	}
}
