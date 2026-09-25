enum Operation {
	Put(id:String);
	Remove;
}

class Main {
	static function decide(operation:Operation, exists:Bool):String {
		final value = switch operation {
			case Put(id):
				if (id != "ok")
					return "rejected";
				"payload";
			case Remove:
				if (!exists)
					return "missing";
				"deleted";
		};
		return "saved:" + value;
	}

	static function main():Void {
		if (decide(Put("bad"), true) != "rejected")
			throw "Switch return did not exit the function.";
		if (decide(Remove, false) != "missing")
			throw "Missing-document return did not exit the function.";
		if (decide(Put("ok"), true) != "saved:payload")
			throw "Valid write changed.";
		if (decide(Remove, true) != "saved:deleted")
			throw "Valid delete changed.";
		if (nested(Put("bad"), true) != "outer")
			throw "Outer switch exit changed.";
		if (nested(Put("ok"), false) != "inner")
			throw "Nested switch exit changed.";
		if (nested(Put("ok"), true) != "saved:inside")
			throw "Nested normal continuation changed.";
		if (closureValue(true) != "saved:closure")
			throw "Closure return escaped its function.";
		if (closureValue(false) != "saved:other")
			throw "Normal alternate branch changed.";
	}

	static function nested(operation:Operation, exists:Bool):String {
		final value = switch operation {
			case Put(id):
				if (id != "ok")
					return "outer";
				final inner = switch operation {
					case Put(_):
						if (!exists)
							return "inner";
						"inside";
					case Remove: "unused";
				};
				inner;
			case Remove: "removed";
		};
		return "saved:" + value;
	}

	static function closureValue(selected:Bool):String {
		final value = if (selected) {
			final callback = function():String {
				return "closure";
			};
			callback();
		} else "other";
		return "saved:" + value;
	}
}
