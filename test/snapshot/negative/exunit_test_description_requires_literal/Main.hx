import haxe.test.ExUnit.TestCase;

@:exunit
class InvalidTestDescription extends TestCase {
	@:test(42)
	function testInvalidDescription():Void {}
}

class Main {
	static function main():Void {}
}
