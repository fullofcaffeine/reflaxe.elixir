/**
 * Regression for haxe.elixir.codex-yshb: the characters `#{` in a Haxe string
 * literal are plain text.
 *
 * Haxe has no `#{...}` syntax, so `"lit #{1 + 1} end"` is the text
 * `lit #{1 + 1} end`. In an Elixir quoted string the same characters start
 * code. The compiler copied the literal into Elixir unchanged, so the program
 * printed `lit 2 end`, or failed to compile when the text named no variable.
 *
 * Every line below prints text that contains `#{`. `expected.stdout` is the
 * output of `haxe -cp . -main Main --interp`.
 */
enum Shape {
	Named(label:String);
}

@:keep
class Main {
	static inline var INLINE_TEXT = "inline #{c} text";
	static var staticText = "static #{f} text";

	static function main():Void {
		var x = 5;
		var name = "n";

		// The two reported lines.
		Sys.println(show("#{x}"));
		Sys.println("lit #{1 + 1} end");

		// A plain literal. The text between the braces can name a real variable,
		// an unknown one, or nothing; it can be incomplete or hold other braces.
		Sys.println("#{x}");
		Sys.println("#{name} and #{unknown} twice");
		Sys.println("#{");
		Sys.println("#{}");
		Sys.println("##{x}");
		Sys.println("nested #{ %{a: 1} } braces");
		Sys.println("quote \" then #{x}");
		Sys.println("call #{raise \"boom\"}");
		// `#` and `{` apart are not a marker and need no escape.
		Sys.println("a # b { c } # {#}");

		// A backslash in front of the marker is text too.
		Sys.println("\\#{x}");
		Sys.println("\\\\#{x}");
		Sys.println("#\\{x}");
		Sys.println("tab\t#{x}\tnl\\n");

		// More than one line.
		Sys.println("line1
#{x}
line3");

		// Literal text next to values. The compiler joins these into one Elixir
		// string, where real values use `#{...}` and the literal marker must not.
		Sys.println(merged(name, x));
		Sys.println(openBrace(name));
		Sys.println(closeBrace(name));
		Sys.println(interpolated(name, x));
		Sys.println(multiLine(name));
		Sys.println("lit #{1 + 1} " + name + " end");
		Sys.println("\\#{x} " + name);

		// A marker that only exists after two pieces of text meet.
		Sys.println(splitMarker());
		Sys.println(splitMarkerAroundValue(name));
		Sys.println("#" + "{x}");

		// Values: variables, comparison, containers, fields, defaults.
		var s = "#{x}";
		Sys.println(s);
		Sys.println(s.length);
		Sys.println(s == "#{x}");
		Sys.println(s == "5");
		var parts = ["#{x}", "b#{name}"];
		Sys.println(parts.join("|"));
		var byKey = ["#{k}" => "#{v}"];
		Sys.println(byKey.get("#{k}"));
		var record = {label: "#{o}"};
		Sys.println(record.label);
		Sys.println(INLINE_TEXT);
		Sys.println(staticText);
		Sys.println(withDefault());
		Sys.println(choose(true));
		Sys.println(choose(false));

		// Patterns.
		Sys.println(classify("#{x}"));
		Sys.println(classify("5"));
		Sys.println(classify("other"));
		switch (Named("#{e}")) {
			case Named(label):
				Sys.println(label);
		}

		// String functions and a regular expression. In `#{1,3}` the braces are
		// a repeat count for `#`.
		Sys.println("a#{x}b".split("#{x}").join("-"));
		Sys.println(StringTools.replace("p #{q} r", "#{q}", "Q"));
		Sys.println("x#{y}".indexOf("#{"));
		Sys.println("#{x}".toUpperCase());
		var heading = ~/^#{1,3} /;
		Sys.println(heading.match("## title"));
		Sys.println(heading.match("title"));
		var buffer = new StringBuf();
		buffer.add("#{b}");
		buffer.add(x);
		Sys.println(buffer.toString());

		// Loops, exceptions, trace.
		var total = "";
		for (i in 0...2)
			total += "#{i}" + i;
		Sys.println(total);
		try {
			throw "#{thrown}";
		} catch (e:String) {
			Sys.println(e);
		}
		trace("#{traced}");

		// A Mix task prints its doc comment and short description as Elixir
		// strings. Both hold `#{name}`; the module must still compile and run.
		Sys.println(MarkerTask.run(["a", "b"]));

		// Target code injection is the one place where `#{...}` must stay code:
		// the author writes Elixir there on purpose. A Haxe literal passed as an
		// argument is still text. Injection has no Haxe interpreter form, so the
		// interpreter prints the same lines directly.
		#if elixir
		untyped __elixir__('IO.puts("injected #{1 + 1}")');
		untyped __elixir__('IO.puts({0})', "argument #{1 + 1}");
		untyped __elixir__('IO.puts("in string: {0} {1}")', "#{x}", name);
		#else
		Sys.println("injected 2");
		Sys.println("argument #{1 + 1}");
		Sys.println("in string: #{x} n");
		#end

		// A literal passed where the function expects an Elixir atom becomes an
		// atom, with the marker escaped inside the quoted atom.
		Sys.println(atomText("c#{d}"));
	}

	#if elixir
	static function atomText(a:elixir.types.Atom):String
		return untyped __elixir__('inspect({0})', a);
	#else
	static function atomText(a:String):String
		return ':"' + StringTools.replace(a, "#{", "\\#{") + '"';
	#end

	public static function show(s:String):String
		return "[" + s + "]";

	static function merged(name:String, x:Int):String
		return "lit #{1 + 1} " + name + " #{x} and #{name} v=" + x;

	static function openBrace(name:String):String
		return "#{" + name + "}";

	static function closeBrace(name:String):String
		return name + " } #{";

	static function interpolated(name:String, x:Int):String
		return 'single ${name} #{name} $x #{${x + 1}}';

	static function multiLine(name:String):String
		return "ml " + name + "
#{x}";

	static function splitMarker():String {
		var hash = "#";
		return hash + "{x}";
	}

	static function splitMarkerAroundValue(name:String):String
		return "a#" + "{" + name + "}" + "#" + "{b}";

	static function withDefault(s:String = "#{d}"):String
		return s;

	static function choose(b:Bool):String
		return b ? "#{t}" : "f#{f}";

	static function classify(s:String):String {
		return switch (s) {
			case "#{x}": "marker";
			case "5": "five";
			default: "other #{s}";
		}
	}
}
