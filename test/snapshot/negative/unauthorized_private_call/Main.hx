class Scope {
	@:allow(Allowed)
	private static function value():Int
		return 7;
}

class Allowed {
	public static function read():Int
		return Scope.value();
}

class Main {
	static function main():Void {
		Sys.println(Allowed.read());
		Sys.println(Scope.value());
	}
}
