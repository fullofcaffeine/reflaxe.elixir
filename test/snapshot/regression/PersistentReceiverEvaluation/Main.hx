/** Receiver setup must survive both persistent-return dispatch conventions. */
class Main {
	static var events:String = "";

	static function buffer():StringBuf {
		events = events + "B";
		return new StringBuf();
	}

	static function text():String {
		events = events + "A";
		return "text";
	}

	static function values():haxe.ds.List<Int> {
		events = events + "L";
		var result = new haxe.ds.List<Int>();
		result.add(7);
		result.add(9);
		return result;
	}

	static function item():Int {
		events = events + "I";
		return 7;
	}

	static function assertTrue(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		buffer().add(text());
		assertTrue(events == "BA", "Evaluate receiver once before argument");
		assertTrue(values().pop() == 7, "Preserve the companion return value");
		assertTrue(values().remove(item()), "Preserve boolean companion result");
		assertTrue(events == "BALLI", "Companion calls must retain receiver and argument order");

		var localBuffer = new StringBuf();
		localBuffer.add("left");
		localBuffer.add("right");
		assertTrue(localBuffer.toString() == "leftright", "Keep direct-local receiver updates");
		var localValues = values();
		assertTrue(localValues.pop() == 7, "Keep the first local companion value");
		assertTrue(localValues.pop() == 9, "Keep local state after companion return");
		assertTrue(localValues.isEmpty(), "Local receiver must retain both removals");
	}
}
