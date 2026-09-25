import probe.Reader;

/** Root helpers retain their actual module identity when a web module is present. */
class Main {
	static function main():Void {
		final reader = new Reader<String>();
		if (reader.run("value") != 7)
			throw "Shared module call returned the wrong value.";
		if (reader.run(42) != -1)
			throw "Native value decoder did not reject an integer.";
	}
}
