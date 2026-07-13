class Main {
	static function fixedPrefix(value:String):String {
		return value.substr(0, 4) + "...";
	}

	public static function main():Void {
		if (fixedPrefix("abcdef") != "abcd...") {
			throw "fixed substr bounds changed";
		}
	}
}
