package tink.testrunner;

import tink.testrunner.Case;
import haxe.PosInfos;

using tink.CoreApi;

#if macro 
import haxe.macro.Context;
using tink.MacroApi;
#end

@:forward
abstract Suite(SuiteObject) from SuiteObject to SuiteObject {
	
	@:from
	public static macro function ofAny(expr:haxe.macro.Expr) {
		var type = Context.typeof(expr);
		
		inline function isType(type, c:String)
			return Context.unify(type, Context.getType('tink.testrunner.$c'));
		
		return switch type {
			case TInst(_.get() => {name: 'Array', pack: []}, [param]) if(isType(param, 'Case')): 
				macro @:pos(expr.pos) tink.testrunner.Suite.ofCases($expr);
			case _ if(isType(type, 'Case')):
				macro @:pos(expr.pos) tink.testrunner.Suite.ofCase($expr);
			case _ if(isType(type, 'Suite.SuiteObject')):
				expr;
			case _:
				expr.pos.error('Cannot cast $type to tink.testrunner.Suite');
		}
	}
	
	public static inline function ofCases<T:Case>(cases:Array<T>, ?pos:PosInfos):Suite
		return new BasicSuite({
			name: [for(c in cases) switch Type.getClass(c) {
				case null: null;
				case c: Type.getClassName(c);
			}].join(', '),
			pos: pos,
		}, cast cases);
	
	public static inline function ofCase(caze:Case, ?pos:PosInfos):Suite
		return ofCases([caze], pos);
		
	public function getCasesToBeRun(includeMode:Bool) {
		return this.cases.filter(function(c) return c.shouldRun(includeMode));
	}
}

typedef SuiteInfo = {
	name:String,
	?pos:PosInfos,
}

interface SuiteObject {
	var info:SuiteInfo;
	var cases:Array<Case>;
	function setup():Promise<Noise>;
	function before():Promise<Noise>;
	function after():Promise<Noise>;
	function teardown():Promise<Noise>;
}

class BasicSuite implements SuiteObject {
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	
	public function new(info:SuiteInfo, cases, ?pos:haxe.PosInfos) {
		this.info = info;
		this.cases = cases;
		if(info.pos == null) info.pos = pos;
		for(c in cases) c.suite = this;
	}
	
	public function setup() return Promise.NOISE;
	public function before() return Promise.NOISE;
	public function after() return Promise.NOISE;
	public function teardown() return Promise.NOISE;
}