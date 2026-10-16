/** A nullable switch must retain constructor matching and payload bindings. */
enum Choice {
	First(id:String);
	Second(id:String);
}

typedef ChoiceAlias = Null<Choice>;
typedef Input = {final choice:ChoiceAlias;}

/** Regression for haxe.elixir.codex-dc6; native expectations live in runtime.exs. */
@:keep
class Main {
	/** The native observer calls the exported methods independently. */
	static function main():Void {}

	public static function first():Choice {
		return First("one");
	}

	public static function second():Choice {
		return Second("two");
	}

	public static function nonnullable(choice:Choice):Bool {
		return switch choice {
			case First(_): true;
			case _: false;
		};
	}

	public static function nullable(choice:ChoiceAlias):Bool {
		return switch choice {
			case First(_): true;
			case _: false;
		};
	}

	public static function payload(choice:ChoiceAlias):String {
		return switch choice {
			case First(id): id;
			case _: "other";
		};
	}

	/** Calling a producer in the switch must evaluate it exactly once. */
	public static function evaluated(source:() -> ChoiceAlias):String {
		return switch source() {
			case First(id): id;
			case _: "other";
		};
	}

	/** A statement switch can reject one constructor and do nothing otherwise. */
	public static function rejectFirst(choice:ChoiceAlias):String {
		switch choice {
			case First(_):
				throw "first";
			case _:
		}

		return "accepted";
	}

	public static function guardedField(input:Input):Bool {
		if (input.choice == null)
			return false;

		return switch input.choice {
			case First(_): true;
			case _: false;
		};
	}
}
