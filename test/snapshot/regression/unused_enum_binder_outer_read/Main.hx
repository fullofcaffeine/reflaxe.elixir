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

/** A result whose payloads have the generic name `v`, which the compiler renames to `value` and `reason`. */
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

/**
 * Regression for haxe.elixir.codex-spk, second part: a pattern binder that the
 * clause does not read, such as `a` in `case SOk(a): "ok " + value`.
 *
 * The compiler names such a payload after the enum field, here `value`. When
 * the clause also reads an outer variable with that name, the binder must get
 * another name, or the clause reads the payload instead. `expected.stdout` is
 * the output of this program on the Haxe interpreter.
 *
 * The same holds when any arm of the switch assigns the outer variable. Elixir
 * does not keep an assignment made inside a `case` arm, so the generated `case`
 * returns the variable from every arm. An arm that does not mention the
 * variable in Haxe then reads it too.
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
		Sys.println(otherArmAssigns(Ok("o")));
		Sys.println(otherArmAssigns(Error("x")));
		for (flag in [true, false]) {
			Sys.println(assignedInIf(Ok("o"), flag));
			Sys.println(assignedInIf(Error("x"), flag));
			Sys.println(nestedAssigned(Wrap(SOk("x")), flag));
			Sys.println(nestedAssigned(Wrap(SErr("x")), flag));
			Sys.println(nestedAssigned(Both("a", "b"), flag));
		}
		Sys.println(otherArmAssignsReason(Ok("o")));
		Sys.println(otherArmAssignsReason(Error("x")));
		Sys.println(reasonLength(Ok("o"), "why"));
		Sys.println(reasonLength(Error("x"), "why"));
	}

	static function note(text:String):Void {
		Sys.println("  note " + text);
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

	/**
	 * Only the `Error` arm assigns `value`. The `Ok` arm does not mention it, but
	 * the generated `case` returns it from both arms.
	 */
	public static function otherArmAssigns(r:Verdict):String {
		var value = "d";
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				value = "err " + e;
		}
		return "r=" + value;
	}

	/** Each arm assigns `value` only when `flag` holds, and never reads it. */
	public static function assignedInIf(r:Verdict, flag:Bool):String {
		var value = "d";
		switch (r) {
			case Ok(v):
				if (flag)
					value = v + "!";
			case Error(e):
				if (flag)
					value = "err";
		}
		return "r=" + value;
	}

	/** A nested pattern whose arms assign `value`, never read it, or do nothing. */
	public static function nestedAssigned(o:Outer, flag:Bool):String {
		var value = "d";
		switch (o) {
			case Wrap(SOk(x)):
				if (flag)
					value = x;
			case Wrap(SErr(_)):
			case Both(_, b):
				value = b;
		}
		return "r=" + value;
	}

	/**
	 * Only the `Ok` arm assigns `reason`; the `Error` arm must return the old
	 * value, not its payload.
	 */
	public static function otherArmAssignsReason(r:Verdict):String {
		var reason = "d";
		switch (r) {
			case Ok(v):
				reason = "ok " + v;
			case Error(e):
				note(e);
		}
		return "r=" + reason;
	}

	/** The `Error` arm reads the argument `reason` outside a string. */
	public static function reasonLength(r:Verdict, reason:String):Int {
		return switch (r) {
			case Ok(v): v.length;
			case Error(e): reason.length * 10 + e.length;
		};
	}
}
