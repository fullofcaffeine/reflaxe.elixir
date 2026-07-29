/**
 * Regression for a non-zero range whose lower bound uses a function argument.
 *
 * The generated range must start at `startIndex + 1`, while the callback body
 * must receive the distinct `index` loop binder. Reusing `startIndex` in the
 * body silently changes which element every iteration observes.
 */
@:native("NonzeroRangeLoopBinder")
@:module
class Main {
	public static function main():Void {
		visit(2, 0, function(_index:Int):Void {});
		findFirst(["open", "close"], 0, 1, "close");
	}

	public static function visit(length:Int, startIndex:Int, callback:Int->Void):Void {
		for (index in (startIndex + 1)...length)
			callback(index);
	}

	public static function findFirst(values:Array<String>, startIndex:Int, endIndex:Int, expected:String):Null<Int> {
		var foundIndex:Null<Int> = null;
		for (index in startIndex...(endIndex + 1)) {
			if (foundIndex == null && values[index] == expected)
				foundIndex = index;
		}
		return foundIndex;
	}
}
