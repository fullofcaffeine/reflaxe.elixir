class Main {
	#if constructor_case
	public function new() {
		var values = [1];
		var alias = values;
		values.push(2);
		trace(alias.length);
	}

	static function main():Void {
		new Main();
	}
	#elseif init_case
	static function __init__():Void {
		var values = [1];
		var alias = values;
		values.push(2);
		trace(alias.length);
	}

	static function main():Void {}
	#elseif used_push_result_case
	static function main():Void {
		var values = [1];
		var alias = values;
		var pushedLength = values.push(2);
		trace(pushedLength);
		trace(alias.length);
	}
	#elseif assigned_push_result_case
	static function main():Void {
		var values = [1];
		var alias = values;
		var pushedLength = 0;
		pushedLength = values.push(2);
		trace(pushedLength);
		trace(alias.length);
	}
	#elseif nested_function_case
	static function main():Void {
		function nested():Void {
			var values = [1];
			var alias = values;
			values.push(2);
			trace(alias.length);
		}

		nested();
	}
	#elseif reverse_case
	static function main():Void {
		var values = [1];
		var alias = values;
		alias.push(2);
		trace(values.length);
	}
	#elseif source_scope_case
	static function main():Void {
		reflaxe.user_case.OwnedTracer.run();
	}
	#else
	static function main():Void {
		var values = [1];
		var alias = values;

		values.push(2);
		trace(alias.length);
	}
	#end
}
