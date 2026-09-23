/** Built-in arrays use list values; a packaged class named Array remains a class. */
class Main {
	static function main():Void {
		var first = new Array<Int>();
		var second = new Array<Int>();
		first.push(7);
		if (first.length != 1 || first[0] != 7 || second.length != 0) {
			throw "array construction or local update failed";
		}
		var custom = new support.Array(5);
		if (custom.seed != 5) {
			throw "packaged Array constructor was replaced";
		}
	}
}
