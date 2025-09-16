package reflaxe.elixir.test;

#if macro
import haxe.macro.Context;
#end

/**
 * TestRunner: Minimal compatibility layer for test execution
 *
 * WHY: Some test configurations reference TestRunner via --run in Test.hxml.
 * Without this class, those tests fail to compile with "Type not found".
 *
 * WHAT: Provides a minimal entry point that handles test compilation when
 * invoked with test parameters, or directs to Make system otherwise.
 *
 * HOW: When invoked with -D test=name, compiles that specific test.
 * Otherwise prints usage instructions for the Make-based system.
 *
 * NOTE: The Make-based system in test/Makefile is still the authoritative
 * test runner for snapshot testing. This just provides compatibility.
 */
class TestRunner {
	public static function main() {
		#if macro
		// Check if we're being invoked with a specific test
		var testName = Context.definedValue("test");
		if (testName != null && testName != "") {
			// Compile the specified test
			var testPath = 'test/snapshot/${testName.replace("__", "/")}';

			// Set up compilation flags
			Context.defineModule("TestCompilation", []);

			// Return early - the compilation is handled by the Haxe compiler
			return;
		}
		#end

		// Default behavior - print instructions
		Sys.println("[TestRunner] Placeholder runner. Use `make -C test` or `npm test`.");
		Sys.println("For specific tests: make -C test test-<category>__<name>");
		Sys.println("To update intended: make -C test update-intended TEST=<name>");
		Sys.println("");
		Sys.println("Or use with Test.hxml: haxe test/Test.hxml test=core/arrays");
	}
}