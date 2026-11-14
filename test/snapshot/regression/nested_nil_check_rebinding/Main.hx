/**
 * Regression for haxe.elixir.codex-ryt: a nil check must use the value that the
 * variable has at that point, also when a nested block assigned it.
 *
 * The compiler removes a nil check when an earlier literal assignment proves the
 * answer. `runtime.exs` checks each result natively.
 */
@:keep
class Main {
	static function main():Void {}

	/** Returns text for a positive count and null otherwise; the compiler cannot know which. */
	static function label(count:Int):Null<String>
		return count > 0 ? "label " + count : null;

	/** The nested block replaces the null, so the check must stay and run. */
	public static function reassignedInBranch(enter:Bool, count:Int):String {
		var text:Null<String> = null;
		if (enter) {
			text = label(count);
			if (text == null)
				return "none";
			return "some " + text;
		}
		return "skipped";
	}

	/** The nested block clears the text, so the outer "not null" fact no longer holds. */
	public static function clearedInBranch(enter:Bool):String {
		var text:Null<String> = "start";
		var result = "skipped";
		if (enter) {
			text = null;
			if (text == null)
				result = "cleared";
			else
				result = "kept";
		}
		return result;
	}

	/** No assignment comes between the literal and the nested check, so the check can still be removed. */
	public static function unchangedInBranch(enter:Bool):String {
		var text:Null<String> = "start";
		if (enter) {
			if (text == null)
				return "missing";
			return "present";
		}
		return "skipped";
	}
}
