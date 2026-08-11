package reflaxe.user_case;

class OwnedTracer {
	public static function run():Void {
		var values = [1];
		var alias = values;
		values.push(2);
		trace(alias.length);
	}
}
