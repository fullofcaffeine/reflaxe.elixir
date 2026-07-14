class Main {
	static function multiplicationTable(source:Array<Int>):Array<Array<Int>> {
		return [for (x in source) [for (y in source) x * y]];
	}

	static function assertMatrix(label:String, expected:Array<Array<Int>>, actual:Array<Array<Int>>):Void {
		if (expected.length != actual.length) {
			throw '$label rows: expected ${expected.length}, got ${actual.length}';
		}
		for (rowIndex in 0...expected.length) {
			var expectedRow = expected[rowIndex];
			var actualRow = actual[rowIndex];
			if (expectedRow.length != actualRow.length) {
				throw '$label row $rowIndex length: expected ${expectedRow.length}, got ${actualRow.length}';
			}
			for (columnIndex in 0...expectedRow.length) {
				if (expectedRow[columnIndex] != actualRow[columnIndex]) {
					throw '$label [$rowIndex][$columnIndex]: expected ${expectedRow[columnIndex]}, got ${actualRow[columnIndex]}';
				}
			}
		}
	}

	public static function main():Void {
		assertMatrix("nested comprehension", [[1, 2, 3], [2, 4, 6], [3, 6, 9]], multiplicationTable([1, 2, 3]));
	}
}
