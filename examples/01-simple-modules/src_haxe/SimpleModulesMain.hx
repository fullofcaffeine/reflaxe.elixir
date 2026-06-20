/**
 * Compile entry point for the simple module examples.
 *
 * The Mix compiler runs one Haxe build file for this example. Keeping a single
 * entry point that references each module ensures all example modules are
 * generated together into lib/ and then checked by Mix and ExUnit.
 */
class SimpleModulesMain {
	public static function main():Void {
		BasicModule.main();
		MathHelper.main();
		UserUtil.main();
	}
}
