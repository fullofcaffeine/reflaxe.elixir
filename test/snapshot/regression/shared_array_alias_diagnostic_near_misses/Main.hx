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

	public static function nestedOverwrite():Int {
		var values = [1];
		var alias = values;
		values.push(2);

		return {
			alias = [];
			alias.length;
		};
	}

	public static function pushArgumentReference():Int {
		var values = [1];
		var alias = values;
		values.push(alias.length);
		return values.length;
	}

	public static function unusedClosure():Int {
		var values = [1];
		var alias = values;
		values.push(2);
		var readLater = () -> alias.length;
		return values.length;
	}

	public static function escapeBeforeAlias():Int {
		var values = [1];
		observe(values);
		var alias = values;
		values.push(2);
		return alias.length;
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
		trace(nestedOverwrite());
		trace(pushArgumentReference());
		trace(unusedClosure());
		trace(escapeBeforeAlias());
	}
}
