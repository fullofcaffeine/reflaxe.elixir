package;

class Main {
	public static function pairedRows(source:Array<Int>):Array<Array<Int>> {
		var rows:Array<Array<Int>> = [];
		for (x in source) {
			var row:Array<Int> = [];
			for (y in source) {
				row.push(x);
				row.push(y);
			}
			rows.push(row);
		}
		return rows;
	}

	public static function main() {
		// Test nested for-in loops with arrays
		var matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]];
		var results = [];

		// Nested loops that Haxe might desugar with infrastructure variables
		for (row in matrix) {
			for (item in row) {
				results.push(item * 2);
			}
		}

		// Test with array comprehension
		var doubled = [for (row in matrix) for (item in row) item * 2];

		// Test with map inside map
		var mapped = matrix.map(row -> row.map(item -> item * 2));

		// Test with nested Enum operations
		var sumOfSums = 0;
		for (row in matrix) {
			var rowSum = 0;
			for (item in row) {
				rowSum += item;
			}
			sumOfSums += rowSum;
		}

		trace(results);
		trace(doubled);
		trace(mapped);
		trace(sumOfSums);
	}
}
