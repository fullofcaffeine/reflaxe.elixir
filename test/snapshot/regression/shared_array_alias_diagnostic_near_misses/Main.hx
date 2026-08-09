class Main {
	public static function sameBinding():Int {
		var values = [1];
		var alias = values;
		values.push(2);
		return values.length;
	}

	public static function readBeforeMutation():Int {
		var values = [1];
		var alias = values;
		trace(alias.length);
		values.push(2);
		return values.length;
	}

	public static function overwrittenAlias():Int {
		var values = [1];
		var alias = values;
		values.push(2);
		alias = [];
		return alias.length;
	}

	public static function branchUncertainty(flag:Bool):Int {
		var values = [1];
		var alias = values;
		if (flag) {
			values.push(2);
		}
		return alias.length;
	}

	public static function branchObservationUncertainty(flag:Bool):Int {
		var values = [1];
		var alias = values;
		values.push(2);
		if (flag) {
			trace(alias.length);
		}
		return values.length;
	}

	public static function escapeUncertainty():Int {
		var values = [1];
		var alias = values;
		observe(values);
		values.push(2);
		return alias.length;
	}

	public static function functionalFlow():Int {
		var values = [1];
		var alias = values;
		values = values.concat([2]);
		return values.length;
	}

	static function observe(_values:Array<Int>):Void {}

	public static function main():Void {
		trace(sameBinding());
		trace(readBeforeMutation());
		trace(overwrittenAlias());
		trace(branchUncertainty(false));
		trace(branchObservationUncertainty(false));
		trace(escapeUncertainty());
		trace(functionalFlow());
	}
}
