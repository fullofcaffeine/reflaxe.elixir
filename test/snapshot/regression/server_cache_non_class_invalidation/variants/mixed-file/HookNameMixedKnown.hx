package;

/**
 * A global hook-name registry that shares its source file with a class.
 * `CacheTemplate` does not refer to this file; only the registry links them.
 */
@:phxHookNames
enum abstract HookName(String) from String to String {
	var Known = "Known";
}

class HookNameNotes {
	public static function note():String {
		return "hook-note-before";
	}
}
