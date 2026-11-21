class Main {
	static function main():Void {
		// A class value keeps DeadTarget in the program, but none of its members.
		final kept:Class<Dynamic> = DeadTarget;
		Sys.println(DeadUser.run() + (kept == null ? 0 : 1));
	}
}
