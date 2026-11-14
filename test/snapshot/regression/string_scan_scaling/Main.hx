/**
 * Character loops over a large string must take time in proportion to its size.
 *
 * `runtime.exs` runs these loops on 800 KB of text with a time budget.
 */
class Main {
	/** Adds every character code: the usual `length` plus `charCodeAt` loop. */
	public static function sumCodes(source:String):Int {
		var total = 0;
		var index = 0;
		while (index < source.length) {
			total += source.charCodeAt(index);
			index++;
		}
		return total;
	}

	/** Counts one character with `charAt`, as a tokenizer does. */
	public static function count(source:String, wanted:String):Int {
		var found = 0;
		var index = 0;
		while (index < source.length) {
			if (source.charAt(index) == wanted)
				found++;
			index++;
		}
		return found;
	}

	/**
	 * Adds the digits of each comma-separated number. Reads a second, short
	 * string (`separator`) inside the loop and cuts each number with `substring`.
	 */
	public static function sumNumbers(source:String, separator:String):Int {
		var total = 0;
		var start = 0;
		var index = 0;
		while (index <= source.length) {
			if (index == source.length || source.substr(index, separator.length) == separator) {
				var number = Std.parseInt(source.substring(start, index));
				if (number != null)
					total += number;
				start = index + separator.length;
			}
			index++;
		}
		return total;
	}

	public static function main():Void {
		Sys.println(sumCodes("12,34") + " " + count("12,34", ",") + " " + sumNumbers("12,34", ","));
	}
}
