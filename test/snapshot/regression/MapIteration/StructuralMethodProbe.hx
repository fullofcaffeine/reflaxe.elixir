/** Structural methods accept both records of functions and class instances. */
typedef StructuralOperation = {
	function combine(value:Int, suffix:Int):Int;
};

class StructuralMethodProbe {
	static var order:String = "";

	static function receiver(classBacked:Bool):StructuralOperation {
		order = order + "receiver;";
		if (classBacked)
			return new StructuralOperationClass(10);
		return {combine: function(value:Int, suffix:Int):Int return 20 + value + suffix};
	}

	static function argument(value:Int):Int {
		order = order + "arg" + value + ";";
		return value;
	}

	static function main() {
		var classResult = receiver(true).combine(argument(1), argument(2));
		if (classResult != 13 || order != "receiver;arg1;arg2;")
			throw "Class-backed structural call changed evaluation order or result";
		order = "";
		var recordResult = receiver(false).combine(argument(3), argument(4));
		if (recordResult != 27 || order != "receiver;arg3;arg4;")
			throw "Record-backed structural call changed evaluation order or result";
		var callback:{combine:(Int, Int) -> Int} = {combine: function(a:Int, b:Int):Int return a * b};
		if (callback.combine(6, 7) != 42)
			throw "Function-valued record field changed";
	}
}

/** Immutable instance data makes prepending the class receiver observable. */
class StructuralOperationClass {
	final base:Int;

	public function new(base:Int)
		this.base = base;

	public function combine(value:Int, suffix:Int):Int
		return base + value + suffix;
}
