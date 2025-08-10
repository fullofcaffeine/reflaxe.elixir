package tink.testrunner;

#if macro 
import haxe.macro.Context;
using tink.MacroApi;
#end

@:forward
abstract Batch(Array<Suite>) from Array<Suite> to Array<Suite> {
	
	public var suites(get, never):Array<Suite>;
	
	public inline function new(suites:Array<Suite>)
		this = suites;
		
	@:from
	public static macro function ofAny(expr:haxe.macro.Expr) {
		var type = Context.typeof(expr);
		
		inline function isType(type, c:String)
			return Context.unify(type, Context.getType('tink.testrunner.$c'));
		
		return switch type {
			case TInst(_.get() => {name: 'Array', pack: []}, [param]) if(isType(param, 'Case')) : 
				macro @:pos(expr.pos) tink.testrunner.Batch.ofCases($expr);
			case TInst(_.get() => {name: 'Array', pack: []}, [param]) if(isType(param, 'Suite')) : 
				macro @:pos(expr.pos) tink.testrunner.Batch.ofSuites($expr);
			case _ if(isType(type, 'Case')):
				macro @:pos(expr.pos) tink.testrunner.Batch.ofCase($expr);
			case _ if(isType(type, 'Suite')):
				macro @:pos(expr.pos) tink.testrunner.Batch.ofSuite($expr);
			case _:
				expr.pos.error('Cannot cast $type to tink.testrunner.Batch');
		}
	}
	
	public static inline function ofSuites<T:Suite>(suites:Array<T>):Batch
		return new Batch(cast suites);
		
	public static inline function ofSuite(suite:Suite):Batch
		return ofSuites([suite]);
	
	public static inline function ofCases<T:Case>(cases:Array<T>, ?pos:haxe.PosInfos):Batch
		return ofSuite(Suite.ofCases(cases, pos));
		
	public static inline function ofCase(caze:Case, ?pos:haxe.PosInfos):Batch
		return ofCases([caze], pos);
		
	inline function get_suites()
		return this;
}