import probe.Label;

class Main {
	static function main():Void {
		if (copyValue("named") != "named!")
			throw "assignment spelling must not discard its value";
		var accepted = Label.parse("valid");
		if (accepted == null || accepted.text() != "valid")
			throw "conditional constructor lost its value";
		if (Label.parse("") != null)
			throw "invalid input was accepted";
		if (Label.identity("unchanged").text() != "unchanged")
			throw "identity constructor lost its value";
		if (Label.choose("left", "right", true).text() != "left")
			throw "true branch lost its value";
		if (Label.choose("left", "right", false).text() != "right")
			throw "false branch lost its value";
		var selected = Label.fromCode(1, "selected");
		if (selected == null || selected.text() != "selected")
			throw "case constructor lost its value";
		var fixed = Label.fromCode(2, "ignored");
		if (fixed == null || fixed.text() != "fixed")
			throw "constant constructor changed";
		if (Label.fromCode(0, "ignored") != null)
			throw "case rejection changed";
	}

	/** Names previously mistaken for compiler scratch bindings still carry values. */
	static function copyValue(value:String):String {
		var newQuery = value + "!";
		var this1 = newQuery;
		return this1;
	}
}
