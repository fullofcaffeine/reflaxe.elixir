private enum PayloadStatus {
	Ready;
	Failed(message:String, code:Int);
}

private enum PayloadResult {
	Value(status:PayloadStatus);
	Missing;
}

private enum ColorChannels {
	Channels(r:Int, g:Int, b:Int);
	Uncolored;
}

private enum PayloadChoice<T> {
	Some(value:T);
	None;
}

private enum UpdateOutcome<T> {
	Ok(value:T);
	Error;
}

/** Independent values must retain their identities inside nested enum patterns. */
class EnumPayloadProbe {
	/** Success tags do not make an outer record interchangeable with an inner payload. */
	static function updatedCaption(outer:UpdateOutcome<{slug:String}>, inner:UpdateOutcome<{slug:String}>):String {
		return switch (outer) {
			case Ok(record):
				switch (inner) {
					case Ok(_updated): 'Selected "${record.slug}".';
					case Error: "inner error";
				}
			case Error: "outer error";
		};
	}

	/** An unused inner payload must not replace a captured outer record in interpolation. */
	static function nestedCaption(outer:PayloadChoice<{slug:String}>, inner:PayloadChoice<{slug:String}>):String {
		return switch (outer) {
			case Some(record):
				switch (inner) {
					case Some(_updated): 'Selected "${record.slug}".';
					case None: "inner missing";
				}
			case None: "outer missing";
		};
	}

	static function wrapped(value:String):PayloadChoice<String> {
		return value.length > 0 ? Some(value) : None;
	}

	static function checkNestedCall(value:String, expected:String):Void {
		switch (wrapped(value)) {
			case Some(text):
				switch (wrapped(text.substr(1))) {
					case Some(tail):
						if (tail != expected) throw "Nested call must match its own result.";
					case None:
						if (expected != "") throw "Nested call lost its empty alternative.";
				}
			case None:
				throw "Outer call unexpectedly returned no value.";
		}
	}

	static function channels(value:ColorChannels):String {
		return switch (value) {
			case Channels(r, g, b): '$r:$g:$b';
			case Uncolored: "none";
		};
	}

	static function choice<T>(value:PayloadChoice<T>, fallback:T):T {
		return switch (value) {
			case Some(v): v;
			case None: fallback;
		};
	}

	static function describe(result:PayloadResult):String {
		return switch (result) {
			case Value(Failed(message, code)): '$code:$message';
			case Value(Ready): "ready";
			case Missing: "missing";
		};
	}

	public static function main():Void {
		if (updatedCaption(Ok({slug: "outer"}), Ok({slug: "inner"})) != 'Selected "outer".'
			|| updatedCaption(Ok({slug: "outer"}), Error) != "inner error"
			|| updatedCaption(Error, Ok({slug: "inner"})) != "outer error")
			throw "Success-case interpolation must retain its outer record.";
		if (nestedCaption(Some({slug: "outer"}), Some({slug: "inner"})) != 'Selected "outer".'
			|| nestedCaption(Some({slug: "outer"}), None) != "inner missing"
			|| nestedCaption(None, Some({slug: "inner"})) != "outer missing")
			throw "Nested interpolation must retain the outer record, not the unused inner payload.";
		checkNestedCall("hello", "ello");
		checkNestedCall("x", "");
		if (channels(Channels(11, 22, 33)) != "11:22:33" || channels(Uncolored) != "none")
			throw "A user binder named g must remain distinct from compiler temporaries.";
		if (choice(Some("present"), "fallback") != "present" || choice(None, "fallback") != "fallback")
			throw "Generic enum extraction lost its payload or fallback.";
		if (describe(Value(Failed("broken", 42))) != "42:broken")
			throw "Nested enum payload identity changed.";
		if (describe(Value(Ready)) != "ready" || describe(Missing) != "missing")
			throw "Nested enum alternatives changed.";
	}
}
