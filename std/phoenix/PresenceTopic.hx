package phoenix;

/**
 * Typed Phoenix Presence topic token.
 *
 * Presence topics are still Elixir strings at runtime. This abstract gives Haxe
 * code a named type so app APIs can say "this value is a Presence topic" without
 * changing the generated Elixir shape.
 */
extern abstract PresenceTopic(String) from String to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function of(value:String):PresenceTopic {
		return new PresenceTopic(value);
	}

	public inline function toString():String {
		return this;
	}
}
