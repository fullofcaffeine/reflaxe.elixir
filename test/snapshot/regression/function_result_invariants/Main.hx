interface ResultCallback {
	function callbackValue(input:Int):Int;
}

@:native("NativeResultCases")
class ResultCases implements ResultCallback {
	public function new() {}

	public function voidResult():Void {}

	@:keep public function raiseOnly():Int {
		throw "intentional";
	}

	public function branchValue(flag:Bool):Int {
		return flag ? 3 : 4;
	}

	public function caseValue(code:Int):String {
		return switch (code) {
			case 1: "one";
			case 2: "two";
			default: "other";
		};
	}

	public function nullableString(flag:Bool):String {
		return flag ? "value" : null;
	}

	public function loopCarrier(values:Array<Int>):Int {
		for (value in values) {
			if (value > 2)
				return value;
		}
		return -1;
	}

	public function callbackValue(input:Int):Int {
		return input + 1;
	}
}

@:native("External.ResultProvider")
extern class ExternalResultProvider {
	static function value():Int;
}

class Main {
	static function main():Void {
		var cases:ResultCallback = new ResultCases();
		var concrete:ResultCases = cast cases;
		concrete.voidResult();
		if (concrete.branchValue(true) != 3)
			throw "branch result lost";
		if (concrete.caseValue(2) != "two")
			throw "case result lost";
		if (concrete.nullableString(false) != null)
			throw "nullable result rejected";
		if (concrete.loopCarrier([1, 3, 5]) != 3)
			throw "loop result carrier lost";
		if (cases.callbackValue(6) != 7)
			throw "callback result lost";
	}
}
