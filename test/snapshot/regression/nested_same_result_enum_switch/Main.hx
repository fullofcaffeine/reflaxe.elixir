/** A result whose two payloads have the generic name `v`. */
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

/**
 * Regression for haxe.elixir.codex-sx27: a switch on a result inside an arm of
 * a switch on another result of the same enum.
 *
 * Each inner arm must read its own payload. Under an outer `Error` arm, the
 * inner `Ok(v)` arm read the outer error payload instead. `expected.stdout` is
 * the output of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		var values = [Ok("p"), Error("why")];
		var others = [Ok("o"), Error("x")];
		for (a in values)
			for (b in others) {
				Sys.println("okInError " + okInError(a, b));
				Sys.println("okInErrorNamed " + okInErrorNamed(a, b));
				Sys.println("bothRead " + bothRead(a, b));
				Sys.println("errorInOk " + errorInOk(a, b));
				Sys.println("statement " + statement(a, b));
				Sys.println("inClosure " + inClosure(a, b));
				for (c in [Ok("3"), Error("z")])
					Sys.println("threeLevels " + threeLevels(a, b, c));
			}
	}

	/** The inner `Ok(v)` arm, under the outer `Error(m)` arm, reads its own payload. */
	public static function okInError(a:Verdict, b:Verdict):Int {
		return switch (a) {
			case Error(m): switch (b) {
					case Ok(v): v.length;
					case Error(x): m.length * 10;
				};
			case Ok(_): -1;
		};
	}

	/** As `okInError`, with the outer binder named `reason` in the Haxe source. */
	public static function okInErrorNamed(a:Verdict, b:Verdict):Int {
		return switch (a) {
			case Error(reason): switch (b) {
					case Ok(v): v.length;
					case Error(x): reason.length * 10;
				};
			case Ok(_): -1;
		};
	}

	/** Every inner arm reads its own payload and the payload of the outer arm. */
	public static function bothRead(a:Verdict, b:Verdict):String {
		return switch (a) {
			case Error(m): switch (b) {
					case Ok(v): "ok " + v + "/" + m;
					case Error(x): "err " + x + "/" + m;
				};
			case Ok(w): switch (b) {
					case Ok(v): "ok " + v + "/" + w;
					case Error(x): "err " + x + "/" + w;
				};
		};
	}

	/** The inner `Error(e)` arm, under the outer `Ok(w)` arm, reads its own payload. */
	public static function errorInOk(a:Verdict, b:Verdict):String {
		return switch (a) {
			case Ok(w): switch (b) {
					case Error(e): "inner error " + e;
					case Ok(_): "ok " + w;
				};
			case Error(_): "outer error";
		};
	}

	/** The nested switch is a statement, and code follows it in the outer arm. */
	public static function statement(a:Verdict, b:Verdict):String {
		var log = "";
		switch (a) {
			case Error(m):
				switch (b) {
					case Ok(v):
						log += "ok " + v;
					case Error(x):
						log += "err " + x;
				}
				log += " after " + m;
			case Ok(w):
				log += "plain " + w;
		}
		return log;
	}

	/** The nested switch stands in a closure that the outer `Error` arm calls. */
	public static function inClosure(a:Verdict, b:Verdict):String {
		return switch (a) {
			case Error(m):
				var describe = function(inner:Verdict):String {
					return switch (inner) {
						case Ok(v): "ok " + v;
						case Error(x): "err " + x + "/" + m;
					};
				};
				describe(b);
			case Ok(w): "plain " + w;
		};
	}

	/** Three levels of the same enum; the innermost arms read all three payloads. */
	public static function threeLevels(a:Verdict, b:Verdict, c:Verdict):String {
		return switch (a) {
			case Error(m): switch (b) {
					case Error(n): switch (c) {
							case Ok(v): "ok " + v + "/" + n + "/" + m;
							case Error(x): "err " + x + "/" + n + "/" + m;
						};
					case Ok(w): switch (c) {
							case Ok(v): "ok " + v + "/" + w + "/" + m;
							case Error(x): "err " + x + "/" + w + "/" + m;
						};
				};
			case Ok(u): switch (b) {
					case Error(n): switch (c) {
							case Ok(v): "ok " + v + "/" + n + "/" + u;
							case Error(x): "err " + x + "/" + n + "/" + u;
						};
					case Ok(_): "ok " + u;
				};
		};
	}
}
