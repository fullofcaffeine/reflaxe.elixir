package;

class Box {
	public var value:String;

	public function new(value:String) {
		this.value = value;
	}
}

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		var value = "first";
		var value2 = "second";
		var box = new Box(value2);

		trace(value);
		trace(box.value);
		assertThat(box.value == "second", "constructor argument numeric suffix was rewritten");
	}
}
