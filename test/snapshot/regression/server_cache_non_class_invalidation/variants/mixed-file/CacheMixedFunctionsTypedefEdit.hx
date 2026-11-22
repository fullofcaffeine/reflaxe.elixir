/**
 * Module-level functions that share their source file with typedefs.
 */
typedef CacheMixedOptions = {
	final scale:Int;
}

/**
 * Read by `CacheMixedPayloadUser` in another file. Elixir writes `+` on two
 * strings as `<>` and on two integers as `+`, so the user's output shows the
 * field type.
 */
typedef CacheMixedPayload = {
	final value:Int;
}

function render(value:Int):String {
	return "functions-before-" + scaled({scale: value});
}

private function scaled(options:CacheMixedOptions):Int {
	return options.scale * 3;
}
