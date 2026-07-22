package;

class Main {
	static function main():Void {}

	public static function externalValue():String {
		return ExternalValueMacro.read();
	}
}
