package tink.testrunner;

import haxe.PosInfos;

using tink.CoreApi;

class Assertion {
	
	public var holds(default, null):AssertionResult;
	public var description(default, null):String;
	public var pos(default, null):PosInfos;

	public function new(holds, description, ?pos:PosInfos) {
		this.holds = holds;
		this.description = description;
		this.pos = pos;
	}

}

abstract AssertionResult(Outcome<Noise, String>) from Outcome<Noise, String> to Outcome<Noise, String> {
	@:from
	public static function ofBool(v:Bool):AssertionResult
		return v ? Success(Noise) : Failure(null);
		
	@:from
	public static function ofOutcome<T>(v:Outcome<T, Error>):AssertionResult
		return switch v {
			case Success(_): Success(Noise);
			case Failure(e): Failure('${e.toString()} ${e.data}');
		}
		
	@:to
	public inline function toBool():Bool
		return this.isSuccess();
		
	@:op(!A) inline function not() return !toBool();
	@:op(A && B) static inline function and_(a:AssertionResult, b:Bool) return a.toBool() && b;
	@:op(A || B) static inline function or_(a:AssertionResult, b:Bool) return a.toBool() || b;
	@:op(A && B) static inline function _and(a:Bool, b:AssertionResult) return a && b.toBool();
	@:op(A || B) static inline function _or(a:Bool, b:AssertionResult) return a || b.toBool();
}