import CacheMixedFunctions.CacheMixedPayload;

/**
 * Uses a typedef of `CacheMixedFunctions.hx` from another file. When the
 * typedef's field type changes, Haxe types this class again, and a warm
 * request must build it again although its own file did not change.
 */
class CacheMixedPayloadUser {
	public static function combine(payload:CacheMixedPayload) {
		return payload.value + payload.value;
	}
}
