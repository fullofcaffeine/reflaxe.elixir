package;

class Main {
	public static function main() {
		trace(hasUnsafeEdge("example.com"));
		trace(hasUnsafeEdge(".example.com"));
		trace(hasUnsafeEdge("example.com-"));
	}

	@:keep
	public static function hasUnsafeEdge(value:String):Bool {
		return value.charAt(0) == "."
			|| value.charAt(0) == "-"
			|| value.charAt(value.length - 1) == "."
			|| value.charAt(value.length - 1) == "-";
	}
}
