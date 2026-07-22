/**
 * A structural value whose field type affects how `+` is compiled.
 *
 * The warm-server regression changes `value` from `String` to `Int` without
 * editing `Main.hx`. A correct cached build must still retype `Main.combine`.
 */
typedef CachePayload = {
	final value:String;
}
