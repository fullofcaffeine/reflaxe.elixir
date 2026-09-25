import elixir.types.Term;
import elixir.types.TermDecoder;
import EnumSubjectProbe.SubjectInput;

/** Inlined native decoding must match its result after an independent enum test. */
class EnumDecoderSubjectProbe {
	static function evaluate(input:SubjectInput, rows:Array<Term>):Int {
		final selected = switch input.choice {
			case Selected(Red): true;
			case _: false;
		};
		if (!selected) {
			final accepted = switch TermDecoder.asBool(rows[0]) {
				case Ok(value): value;
				case Error(_): false;
			};
			if (accepted)
				return 20;
		}
		return 10;
	}

	public static function main():Void {
		if (evaluate({choice: Selected(Red)}, [true]) != 10
			|| evaluate({choice: Selected(Blue)}, [true]) != 20
			|| evaluate({choice: Selected(Blue)}, [false]) != 10
			|| evaluate({choice: None}, [true]) != 20
			|| evaluate({choice: None}, [false]) != 10
			|| evaluate({choice: None}, ["not a boolean"]) != 10)
			throw "The decoder switch must read its own result";
	}
}
