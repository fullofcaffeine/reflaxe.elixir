/** A result whose payloads are declared as `value` and `e`. */
enum SRes {
	SOk(value:String);
	SErr(e:String);
}

/** A result with the names that Elixir code usually gives `{:ok, _}` and `{:error, _}`. */
enum Reply {
	Ok(value:Int);
	Error(reason:String);
}

/** A value that carries a result, or two strings. */
enum Outer {
	Wrap(value:SRes);
	Both(value:String, e:String);
}

/**
 * Regression for haxe.elixir.codex-spk, second part: a pattern binder that the
 * clause does not read, such as `a` in `case SOk(a): "ok " + value`.
 *
 * The compiler names such a payload after the enum field, here `value`. When
 * the clause also reads an outer variable with that name, the binder must get
 * another name, or the clause reads the payload instead. `expected.stdout` is
 * the output of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		Sys.println(outerArgument(SOk("x"), "P"));
		Sys.println(outerArgument(SErr("x"), "P"));
		Sys.println(outerNilLocal(SOk("x")));
		Sys.println(outerSetLocal(SOk(null)));
		Sys.println(replyArgument(Ok(1), 50));
		Sys.println(replyReason(Error("bad"), "why"));
		Sys.println(innerSwitch(SOk("x"), SOk("in"), "P"));
		Sys.println(innerSwitch(SOk("x"), SErr("in"), "P"));
		Sys.println(nestedPattern(Wrap(SOk("x"))));
		Sys.println(nestedPattern(Wrap(SErr("x"))));
		Sys.println(nestedPattern(Both("a", "b")));
		Sys.println(secondPayload(Both("a", "b"), "P"));
		Sys.println(secondPayload(Wrap(SOk("x")), "P"));
	}

	/** Reads the function argument `value`; `a` and `b` are not read. */
	public static function outerArgument(r:SRes, value:String):String {
		return switch (r) {
			case SOk(a): "ok " + value;
			case SErr(b): "err " + value;
		};
	}

	/** Tests an outer local `value` that is null. */
	public static function outerNilLocal(r:SRes):String {
		var value:Null<String> = null;
		return switch (r) {
			case SOk(a): value == null ? "outer nil" : "outer set";
			case SErr(_): "e";
		};
	}

	/** Tests an outer local `value` that is set, while the payload is null. */
	public static function outerSetLocal(r:SRes):String {
		var value:Null<String> = "lit";
		return switch (r) {
			case SOk(a): value == null ? "outer nil" : "outer set";
			case SErr(_): "e";
		};
	}

	/** Reads the argument `value` in an `Ok(a)` clause that does not read `a`. */
	public static function replyArgument(r:Reply, value:Int):Int {
		return switch (r) {
			case Ok(a): value + 1;
			case Error(_): -value;
		};
	}

	/** Reads the argument `reason` in an `Error(x)` clause that does not read `x`. */
	public static function replyReason(r:Reply, reason:String):String {
		return switch (r) {
			case Ok(_): reason;
			case Error(x): "err/" + reason;
		};
	}

	/** Reads the argument before an inner switch that binds the same name. */
	public static function innerSwitch(r:SRes, inner:SRes, value:String):String {
		return switch (r) {
			case SOk(a):
				value + "|" + (switch (inner) {
					case SOk(value): value;
					case SErr(_): "e";
				});
			case SErr(_): "err";
		};
	}

	/**
	 * A nested pattern has no Haxe name for the outer payload, so the compiler
	 * must make up a name that differs from the outer local `value`.
	 */
	public static function nestedPattern(o:Outer):String {
		var value = "d";
		switch (o) {
			case Wrap(SOk(_)):
				value = value + "w";
			case Wrap(SErr(_)):
				value = value + "e";
			case Both(_, b):
				value = b;
		}
		return value;
	}

	/** The first of two payloads is not read; the clause reads the argument. */
	public static function secondPayload(o:Outer, value:String):String {
		return switch (o) {
			case Both(a, b): value + b;
			case Wrap(_): value;
		};
	}
}
