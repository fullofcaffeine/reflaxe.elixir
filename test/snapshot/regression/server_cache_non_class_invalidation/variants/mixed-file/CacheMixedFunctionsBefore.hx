/**
 * Module-level functions that share their source file with a typedef.
 */
typedef CacheMixedOptions = {
	final scale:Int;
}

function render(value:Int):String {
	return "functions-before-" + scaled({scale: value});
}

private function scaled(options:CacheMixedOptions):Int {
	return options.scale * 3;
}
