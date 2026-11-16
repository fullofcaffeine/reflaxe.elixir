// Differential fixture o03_later, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o03_later
import haxe.ds.Option;

enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// Option with an argument named value
	static function opt(o:Option<String>, value:String):String {
		switch (o) {
			case Some(v):
				note(v);
			case None:
				return "none";
		}
		return "r=" + value;
	}

	// Switch within switch default with visible pattern binder named reason
	static function patternBinder(a:Verdict, b:Verdict):String {
		switch (a) {
			case Error(reason):
				switch (b) {
					case Error(e):
						note(e);
					case Ok(o):
						return "ok " + o;
				}
				return "r=" + reason;
			case Ok(o):
				return "outer " + o;
		}
	}

	// Static var used as visible name? Static field named value read after switch
	static var value:String = "STATIC";

	static function staticField(r:Verdict):String {
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		return "r=" + value;
	}

	// Reserved-word-ish Haxe names: local named `end` / `fn`
	static function reserved(r:Verdict):String {
		var when = "W";
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		return "r=" + when;
	}

	// camelCase local mapping to snake_case collision with binder candidate
	static function camel(r:Named2, fooBar:String):String {
		switch (r) {
			case Thing(x):
				note(x);
			case Other:
				return "other";
		}
		return "r=" + fooBar;
	}

	// guarded switch with moved code
	static function guardedMoved(r:Verdict, value:String):String {
		switch (r) {
			case Ok(v) if (v.length > 1):
				note("long " + v);
			case Ok(v):
				note("short " + v);
			case Error(e):
				return "err " + e;
		}
		return "r=" + value;
	}

	// switch on tuple-ish (two enums via array)
	static function nullableArg(r:Verdict, ?reason:String):String {
		switch (r) {
			case Error(e):
				note(e);
			case Ok(o):
				return "ok " + o;
		}
		return "r=" + reason;
	}

	static function main() {
		Sys.println("opt " + opt(Some("s"), "V") + " " + opt(None, "V"));
		for (r in [Ok("oo"), Ok("o"), Error("x")]) {
			Sys.println("staticField " + staticField(r));
			Sys.println("reserved " + reserved(r));
			Sys.println("guardedMoved " + guardedMoved(r, "V"));
			Sys.println("nullableArg " + nullableArg(r, "R") + " " + nullableArg(r));
			for (s in [Ok("p"), Error("y")])
				Sys.println("patternBinder " + patternBinder(r, s));
		}
		Sys.println("camel " + camel(Thing("t"), "FB") + " " + camel(Other, "FB"));
	}
}

enum Named2 {
	Thing(foo_bar:String);
	Other;
}
