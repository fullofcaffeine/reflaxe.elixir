import HXX;

typedef PageAssigns = {name:String, on:Bool};

/**
 * Regression for haxe.elixir.codex-yshb, review round 2: a function that takes
 * `assigns` and returns HTML text is a template route.
 *
 * The compiler turns such a return into a `~H` template, and `#{...}` in that
 * text becomes the template output `<%= ... %>`. This is the same rule as for
 * `HXX.hxx(...)`. The functions in the first group must print `~H`, whether
 * their text holds `#{` or not.
 *
 * Text that does not become a template is an ordinary Haxe string. Its `#{`
 * stays plain text and prints escaped (`\#{`): see the second group.
 */
@:hxx_mode("balanced")
@:keep
class Main {
	// Template route: `#{...}` becomes `<%= ... %>` inside `~H`.
	public static function render(assigns:PageAssigns):String
		return "<p>Hello #{assigns.name}</p>";

	public static function help(assigns:PageAssigns):String
		return "<p>Write #{1 + 1} to #{assigns.name}</p>";

	public static function helpPlain(assigns:PageAssigns):String
		return "<p>No marker</p>";

	public static function viaVar(assigns:PageAssigns):String {
		var html = "<i>#{assigns.name}</i>";
		return html;
	}

	// `inner` holds HTML, so the template prints it with `Phoenix.HTML.raw`.
	public static function nested(assigns:PageAssigns):String {
		var inner = assigns.on ? "<b>on</b>" : "<i>off</i>";
		return "<div>#{inner}</div>";
	}

	// The returned text is the template. The argument of `shout` is not.
	public static function mixed(assigns:PageAssigns):String {
		var title = shout("#{raw}");
		return "<h2>#{title}</h2>";
	}

	// A parameter that only the template reads keeps its name; `~H` reads `extra`.
	public static function cell(assigns:PageAssigns, extra:String):String
		return "<td>#{extra}</td>";

	// `inner` holds HTML text with a marker of its own. The HXX template still
	// prints it with `Phoenix.HTML.raw`; the text of `inner` itself is not a
	// template, so its marker stays text.
	public static function htmlVarHxx(assigns:PageAssigns):String {
		var inner = "<b>#{assigns.name}</b>";
		Sys.println(inner);
		return HXX.hxx('<div>#{inner}</div>');
	}

	// Ordinary strings: `#{` stays text.
	// Not HTML and not the returned value. The compiler rewrites the inner `if`
	// of this `switch`, but must not turn this text into a template.
	public static function kind(assigns:PageAssigns):String {
		var kind = switch (assigns.name) {
			case "a": "first";
			case other if (other == "b"): "second";
			default: "write #{System.halt(1)} here";
		};
		return "<span>" + kind + "</span>";
	}

	// Takes `assigns`, but the text is not HTML and the function is not `render`.
	public static function label(assigns:PageAssigns):String
		return "no tags #{assigns.name}";

	// HTML text, but no `assigns` parameter.
	public static function plain(name:String):String
		return "<p>#{name}</p>";

	public static function shout(text:String):String
		return text.toUpperCase();

	static function main() {}
}
