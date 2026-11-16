/** A result whose two payloads have the generic name `v`. */
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

/**
 * Regression for haxe.elixir.codex-1h8a: a `catch` inside a result arm.
 *
 * The compiler lowers a Haxe `catch` to an Elixir `rescue` that binds the
 * exception as `haxe_exception`. Each function below has a `try`/`catch`
 * inside an `Ok(v)` or `Error(v)` arm and reads the arm's payload. The payload
 * read must keep reading the payload, whatever the catch variable is named:
 * `value`, `reason`, or the payload's own name. `expected.stdout` is the output
 * of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("value " + catchValue(r));
			Sys.println("reason " + catchReason(r));
			Sys.println("shadow " + catchShadow(r));
			Sys.println("dynamic " + catchDynamic(r));
			Sys.println("unused " + catchUnused(r));
			Sys.println("nested " + nestedTry(r));
			Sys.println("closure " + catchInClosure(r));
			Sys.println("exception " + catchException(r));
		}
	}

	/** The catch variable is named `value` in both arms. */
	public static function catchValue(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (value:String) {
					value + v;
				}
			case Error(v):
				try {
					throw "U";
				} catch (value:String) {
					value + v;
				}
		};
	}

	/** The catch variable is named `reason` in both arms. */
	public static function catchReason(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (reason:String) {
					reason + v;
				}
			case Error(v):
				try {
					throw "U";
				} catch (reason:String) {
					reason + v;
				}
		};
	}

	/** The catch variable has the payload's own name and hides it. */
	public static function catchShadow(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				var kept = v;
				try {
					throw "T";
				} catch (v:String) {
					v + kept;
				}
			case Error(v):
				var kept = v;
				try {
					throw "U";
				} catch (v:String) {
					v + kept;
				}
		};
	}

	/** An untyped catch named `value`. */
	public static function catchDynamic(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (value:Dynamic) {
					(value : String) + v;
				}
			case Error(v):
				try {
					throw "U";
				} catch (reason:Dynamic) {
					(reason : String) + v;
				}
		};
	}

	/** The catch variable is not read; the payload is. */
	public static function catchUnused(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (value:String) {
					v;
				}
			case Error(v):
				try {
					throw "U";
				} catch (reason:String) {
					v;
				}
		};
	}

	/** An inner catch that does not match passes the value to the outer one. */
	public static function nestedTry(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					try {
						throw "T";
					} catch (value:Int) {
						"int" + v;
					}
				} catch (value:String) {
					value + v;
				}
			case Error(v):
				try {
					try {
						throw "U";
					} catch (reason:Int) {
						"int" + v;
					}
				} catch (reason:String) {
					reason + v;
				}
		};
	}

	/** The catch stands inside a closure in the arm. */
	public static function catchInClosure(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				var f = function():String {
					try {
						throw "T";
					} catch (value:String) {
						return value + v;
					}
				};
				f();
			case Error(v):
				var f = function():String {
					try {
						throw "U";
					} catch (reason:String) {
						return reason + v;
					}
				};
				f();
		};
	}

	/** A catch of the base Haxe exception reads its message. */
	public static function catchException(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw new haxe.Exception("T");
				} catch (value:haxe.Exception) {
					value.message + v;
				}
			case Error(v):
				try {
					throw new haxe.Exception("U");
				} catch (reason:haxe.Exception) {
					reason.message + v;
				}
		};
	}
}
