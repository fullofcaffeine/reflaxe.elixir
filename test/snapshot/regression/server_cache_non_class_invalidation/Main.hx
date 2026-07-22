/**
 * Output-sensitive callers for warm Haxe compilation-server invalidation.
 *
 * The server test edits only CacheStatus, CachePayload, or CacheCode. These
 * functions make the affected type decision visible in generated Elixir, so a
 * stale cached result cannot hide behind a successful Haxe compilation.
 */
class Main {
	static function main():Void {}

	public static function currentStatus():CacheStatus {
		return Ready;
	}

	public static function combine(payload:CachePayload) {
		return payload.value + payload.value;
	}

	public static function render(code:CacheCode):Int {
		return code.render();
	}
}
