/** Uses `Base`, `Host` and the class that `Gen.build` defines. */
class Main {
	static function main():Void {
		Sys.println(Host.v());
		Sys.println(HostCompanion.label());
	}
}
