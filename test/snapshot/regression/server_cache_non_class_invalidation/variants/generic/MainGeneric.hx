/** Uses one instance of a generic class (see `run_generic_variant`). */
class Main {
	static function main():Void {
		Sys.println(new EarlyBox<String>("value").describe());
	}
}
