package;

typedef PageAssigns = {name:String, on:Bool};

/**
 * HEEx return conversion must not depend on tree object identity.
 *
 * WHAT
 * - `render/1` that only delegates to other functions, behind an `if`, keeps its body:
 *   it is not replaced with a `~H` sigil. Both the statement form and the conditional
 *   expression form are covered.
 * - A helper that takes `assigns` and holds a plain `if` keeps its body and its `assigns`
 *   parameter; a parenthesized HTML string body still becomes `~H`.
 *
 * WHY
 * - `HeexStringReturnToSigilTransforms` decides whether a body took part in the conversion.
 *   It used to read that from `newBody != body`. When the traversal engine started to keep a
 *   node that a callback only copied, a rebuilt `if` came back as the same object, and the
 *   `render/1` fallback replaced the delegating body with `~H`. The pass now uses an explicit
 *   flag. Expected output is the output of commit `5aa5fdf0a`.
 */
@:hxx_mode("balanced")
@:keep
class Main {
	public static function render(assigns:PageAssigns):String {
		if (assigns.on)
			return Views.compact(assigns);
		return Views.full(assigns);
	}

	static function badgeClass(assigns:PageAssigns, flag:Bool):String {
		var label = flag ? "on" : "off";
		return label.toUpperCase();
	}

	public static function badge(assigns:PageAssigns, flag:Bool):String
		return badgeClass(assigns, flag);

	public static function card(assigns:PageAssigns):String
		return ("<div>hi</div>");

	static function main() {}
}

@:hxx_mode("balanced")
@:keep
class Second {
	public static function render(assigns:PageAssigns):String
		return assigns.on ? Views.compact(assigns) : Views.full(assigns);
}

@:keep
class Views {
	public static function compact(page:PageAssigns):String
		return "compact " + page.name;

	public static function full(page:PageAssigns):String
		return "full " + page.name;
}
