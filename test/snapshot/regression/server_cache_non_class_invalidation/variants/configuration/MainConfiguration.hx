/**
 * Makes an HXML-only configuration change visible in generated Elixir.
 *
 * The regression script leaves this source untouched while it adds and removes
 * `-D server_cache_feature` from compile.hxml. A warm request must therefore
 * select the correct Haxe typing context instead of reusing the previous one.
 */
class Main {
	static function main():Void {}

	public static function configuredValue():String {
		#if server_cache_feature
		return "enabled";
		#else
		return "disabled";
		#end
	}
}
