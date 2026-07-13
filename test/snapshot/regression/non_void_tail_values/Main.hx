class TailValues {
	public function new() {}

	public function intLiteral(_ignored:Int):Int {
		return 0;
	}

	public function boolLiteral():Bool {
		return false;
	}

	public function stringLiteral():String {
		return "tail";
	}

	public function floatLiteral():Float {
		return 1.5;
	}

	public function nullLiteral():Null<String> {
		return null;
	}

	public function arrayLiteral():Array<Int> {
		return [1, 2, 3];
	}

	public function objectLiteral():{value:Int} {
		return {value: 7};
	}

	public function tupleLiteral():{_1:String, _2:Int} {
		return {_1: "tuple", _2: 4};
	}

	public function localValue(value:Int):Int {
		return value;
	}

	public function callValue():Int {
		return intLiteral(9);
	}

	public function branchValue(flag:Bool):Int {
		return flag ? 1 : 2;
	}
}

class Main {
	static function main():Void {
		var values = new TailValues();
		if (values.intLiteral(9) != 0)
			throw "int tail value lost";
		if (values.boolLiteral() != false)
			throw "bool tail value lost";
		if (values.stringLiteral() != "tail")
			throw "string tail value lost";
		if (values.floatLiteral() != 1.5)
			throw "float tail value lost";
		if (values.nullLiteral() != null)
			throw "null tail value lost";

		var arrayValue = values.arrayLiteral();
		if (arrayValue.length != 3 || arrayValue[0] != 1 || arrayValue[2] != 3)
			throw "array tail value lost";

		var objectValue = values.objectLiteral();
		if (objectValue.value != 7)
			throw "object tail value lost";

		var tupleValue = values.tupleLiteral();
		if (tupleValue._1 != "tuple" || tupleValue._2 != 4)
			throw "tuple tail value lost";
		if (values.localValue(11) != 11)
			throw "local tail value lost";
		if (values.callValue() != 0)
			throw "call tail value lost";
		if (values.branchValue(true) != 1 || values.branchValue(false) != 2)
			throw "branch tail value lost";
	}
}
