class Main {
	static function main():Void {
		var values = [1];
		var alias = values;

		values.push(2);
		trace(alias.length);
	}
}
