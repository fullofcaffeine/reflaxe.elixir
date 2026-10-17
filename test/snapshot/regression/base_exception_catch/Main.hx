/** The alias must retain the base exception catch contract. */
typedef BaseException = haxe.Exception;

class DerivedFailure extends haxe.Exception {
	public function new() {
		super("derived");
	}
}

/** Exercise base-exception catch semantics independently of consumer code. */
@:keep
class Main {
	public static function main():Void {
		if (!catchesString())
			throw "String escaped its exception handler.";
		if (message(false) != "expected")
			throw "String message changed.";
		if (message(true) != "object")
			throw "Exception message changed.";
		if (ordered(false) != "string:expected")
			throw "Typed catch order changed.";
		if (ordered(true) != "base:object")
			throw "Base catch changed.";
		if (derivedMessage() != "derived")
			throw "Subclass message changed.";
	}

	public static function catchesString():Bool {
		var caught = false;
		try
			fail(false)
		catch (_:haxe.Exception)
			caught = true;
		return caught;
	}

	public static function message(object:Bool):String {
		return try {
			fail(object);
			"not caught";
		} catch (error:haxe.Exception) {
			error.message;
		};
	}

	public static function ordered(object:Bool):String {
		return try {
			fail(object);
			"not caught";
		} catch (text:String) {
			"string:" + text;
		} catch (error:haxe.Exception) {
			"base:" + error.message;
		};
	}

	public static function aliased(action:Void->Void):String {
		return try {
			action();
			"not caught";
		} catch (error:BaseException) {
			error.message;
		};
	}

	public static function numberOnly(action:Void->Void):Int {
		return try {
			action();
			0;
		} catch (number:Int) {
			number;
		};
	}

	public static function caughtObject(action:Void->Void):Null<haxe.Exception> {
		return try {
			action();
			null;
		} catch (error:haxe.Exception) {
			error;
		};
	}

	public static function derivedMessage():String {
		return try {
			throw new DerivedFailure();
			"not caught";
		} catch (error:haxe.Exception) {
			error.message;
		};
	}

	@:noInline static function fail(object:Bool):Void {
		if (object)
			throw new haxe.Exception("object");
		throw "expected";
	}
}
