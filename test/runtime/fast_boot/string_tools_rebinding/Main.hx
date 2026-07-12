class Main {
	public static function main():Void {
		var left = StringTools.lpad("x", "0", 3);
		var right = StringTools.rpad("x", "0", 3);

		if (left != "00x")
			throw 'Expected 00x, got $left';
		if (right != "x00")
			throw 'Expected x00, got $right';
	}
}
