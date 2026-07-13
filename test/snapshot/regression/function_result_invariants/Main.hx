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

@:native("Process")
extern class StatementProcess {
	@:native("Process.put")
	static function put(key:String, value:Int):Dynamic;

	@:native("Process.get")
	static function get(key:String, defaultValue:Int):Int;
}

@:native("StatementEffectProbe")
class StatementEffectProbe {
	public static function reset():Void {
		StatementProcess.put("reflaxe_statement_effect_probe", 0);
	}

	public static function record(value:Int):Int {
		var current = StatementProcess.get("reflaxe_statement_effect_probe", 0);
		StatementProcess.put("reflaxe_statement_effect_probe", current * 10 + value);
		return value;
	}

	public static function tailRecord(value:Int):Int {
		return record(value);
	}

	public static function current():Int {
		return StatementProcess.get("reflaxe_statement_effect_probe", 0);
	}
}

class Main {
	static function main():Void {
		var cases:ResultCallback = new ResultCases();
		var concrete:ResultCases = cast cases;
		concrete.voidResult();
		StatementEffectProbe.reset();
		StatementEffectProbe.record(1);
		StatementEffectProbe.record(2);
		if (StatementEffectProbe.current() != 12)
			throw "statement effects were dropped";
		StatementEffectProbe.reset();
		var difference = StatementEffectProbe.record(4) - StatementEffectProbe.record(1);
		if (difference != 3 || StatementEffectProbe.current() != 41)
			throw "embedded call order changed";
		StatementEffectProbe.reset();
		if (StatementEffectProbe.tailRecord(7) != 7 || StatementEffectProbe.current() != 7)
			throw "tail call value lost";
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
