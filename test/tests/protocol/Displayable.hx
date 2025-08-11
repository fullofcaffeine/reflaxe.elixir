package;

/**
 * Protocol compiler test case
 * Tests @:protocol annotation compilation
 */
@:protocol
interface Displayable {
	function display(): String;
	function format(options: Dynamic): String;
}

// Implementation for String
@:impl(Displayable)
class StringDisplay {
	public static function display(value: String): String {
		return value;
	}
	
	public static function format(value: String, options: Dynamic): String {
		if (options.uppercase) {
			return value.toUpperCase();
		}
		return value;
	}
}

// Implementation for Int
@:impl(Displayable)
class IntDisplay {
	public static function display(value: Int): String {
		return Std.string(value);
	}
	
	public static function format(value: Int, options: Dynamic): String {
		if (options.hex) {
			return "0x" + StringTools.hex(value);
		}
		return Std.string(value);
	}
}

// Implementation for custom type
class User {
	public var name: String;
	public var age: Int;
	
	public function new(name: String, age: Int) {
		this.name = name;
		this.age = age;
	}
}

@:impl(Displayable)
class UserDisplay {
	public static function display(user: User): String {
		return '${user.name} (${user.age})';
	}
	
	public static function format(user: User, options: Dynamic): String {
		if (options.verbose) {
			return 'User: ${user.name}, Age: ${user.age}';
		}
		return display(user);
	}
}