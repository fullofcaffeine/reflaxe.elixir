/**
 * One module with several types: a class, an enum, a typedef and an abstract.
 * An abstract also has a hidden implementation class in the same module.
 */
class EarlyMulti {
	public static function label():String
		return "multi-before";
}

enum EarlyKind {
	First;
	Second;
}

typedef EarlyShape = {
	final name:String;
}

abstract EarlyCode(Int) from Int to Int {
	public inline function render():Int {
		return this + 1;
	}
}
