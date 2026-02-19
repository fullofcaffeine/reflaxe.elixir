package interop;

/**
 * LegacySlugBridge
 *
 * WHAT
 * - Small Haxe wrapper over `LegacySlugExtern`.
 *
 * WHY
 * - Wrappers keep interop details in one place and give the app a stable,
 *   intention-revealing API.
 *
 * HOW
 * - Delegates to the hand-written Elixir implementation via the typed extern.
 *
 * EXAMPLE
 * - `LegacySlugBridge.normalizeLabel("Phoenix LiveView")` -> `"phoenix-liveview"`
 */
class LegacySlugBridge {
	public static function normalizeLabel(value:String):String {
		return LegacySlugExtern.normalize(value);
	}
}
