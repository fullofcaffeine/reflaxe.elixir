// Module-level functions. Haxe puts them in the class `DceFields_Fields_`.
// The `@:native` of `named` also names that module. Under `-dce full`, `named`
// is removed while nothing calls it; a fresh build still names the module
// `DceNamedFields`, and so must a warm build.

@:native("DceNamedFields")
function named():Int
	return 1;

function plain():Int
	return 2;
