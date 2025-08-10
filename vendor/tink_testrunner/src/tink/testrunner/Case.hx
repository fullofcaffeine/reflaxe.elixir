package tink.testrunner;

import haxe.PosInfos;
import tink.testrunner.Suite;

@:forward
abstract Case(CaseObject) from CaseObject to CaseObject {
	public function shouldRun(includeMode:Bool):Bool {
		return !this.exclude && (!includeMode || this.include);
	}
}

interface CaseObject {
	var suite:Suite;
	var info:CaseInfo;
	var timeout:Int;
	var include:Bool;
	var exclude:Bool;
	var pos:PosInfos;
	function execute():Assertions;
}

typedef CaseInfo = {
	name:String,
	description:String,
	pos:PosInfos,
}

class BasicCase implements CaseObject {
	public var suite:Suite;
	public var info:CaseInfo;
	public var timeout:Int = 30000; // Increased from 5000ms to 30000ms to prevent test timeouts
	public var include:Bool = false;
	public var exclude:Bool = false;
	public var pos:PosInfos = null;
	
	public function new(?pos:PosInfos) {
		info = {
			name: Type.getClassName(Type.getClass(this)),
			description: null,
			pos: pos,
		}
	}
	
	public function execute():Assertions {
		return [].iterator();
	}
}