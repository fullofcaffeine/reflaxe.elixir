import haxe.functional.Result;

enum SubjectColor {
	Red;
	Blue;
}

enum SubjectChoice {
	Selected(color:SubjectColor);
	None;
}

typedef SubjectInput = {
	final choice:SubjectChoice;
}

/** Nested constant patterns and later result switches must keep distinct values. */
class EnumSubjectProbe {
	static var classifications:Int = 0;

	static function classify(value:Int):Result<Bool, String> {
		classifications = classifications + 1;
		return value < 0 ? Error("negative") : Ok(value > 0);
	}

	static function evaluate(input:SubjectInput, value:Int):Int {
		final selected = switch input.choice {
			case Selected(Red): true;
			case _: false;
		};
		if (!selected) {
			final accepted = switch classify(value) {
				case Ok(result): result;
				case Error(_): false;
			};
			if (accepted)
				return 20;
		}
		return 10;
	}

	public static function main():Void {
		classifications = 0;
		if (evaluate({choice: Selected(Red)}, 1) != 10
			|| evaluate({choice: Selected(Red)}, 0) != 10
			|| evaluate({choice: Selected(Red)}, -1) != 10
			|| classifications != 0)
			throw "Matching the nested constructor must skip the later call";
		if (evaluate({choice: Selected(Blue)}, 1) != 20
			|| evaluate({choice: Selected(Blue)}, 0) != 10
			|| evaluate({choice: Selected(Blue)}, -1) != 10
			|| evaluate({choice: None}, 1) != 20
			|| evaluate({choice: None}, 0) != 10
			|| evaluate({choice: None}, -1) != 10
			|| classifications != 6)
			throw "Nested payload or independent result subject changed";
	}
}
