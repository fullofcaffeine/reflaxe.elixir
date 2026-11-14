/** When the next event is due. */
enum NextEvent {
	Now;
	Never;
	At(time:Float);
}

/**
 * Regression for a switch whose catch-all case names the value and uses the
 * name only in a `throw`.
 *
 * The tested expression must run once, and the name must hold its value.
 * `runtime.exs` counts the calls natively.
 */
@:keep
class Main {
	static function main():Void {}

	/** Throws unless `next` reports `Now`. `next` is a native callback, so the test can count its calls. */
	public static function requireNow(next:Void->NextEvent):String {
		switch next() {
			case Now:
			case other:
				throw 'expected Now, got $other';
		}
		return "now";
	}
}
