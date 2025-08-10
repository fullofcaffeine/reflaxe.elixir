package test;

/**
 * Test Runner for Reflaxe.Elixir Compiler
 * 
 * Based on Reflaxe.CPP and Reflaxe.CSharp testing patterns.
 * Compiles test Haxe files and compares output with intended Elixir files.
 * 
 * Usage:
 *   haxe Test.hxml                  # Run all tests
 *   haxe Test.hxml test=liveview    # Run specific test
 *   haxe Test.hxml update-intended  # Update intended output files
 *   haxe Test.hxml show-output      # Show compilation output
 *   haxe Test.hxml help             # Show help
 */
class TestRunner {
	// Constants
	static final TEST_DIR = "test/tests";
	static final OUT_DIR = "out";
	static final INTENDED_DIR = "intended";
	
	// Options
	static var UpdateIntended = false;
	static var ShowAllOutput = false;
	static var NoDetails = false;
	static var SpecificTests: Array<String> = [];
	
	public static function main() {
		// Parse command line arguments
		final args = Sys.args();
		
		if (args.contains("help")) {
			showHelp();
			return;
		}
		
		// Parse options
		UpdateIntended = args.contains("update-intended");
		ShowAllOutput = args.contains("show-output");
		NoDetails = args.contains("no-details");
		
		// Parse specific tests
		for (arg in args) {
			if (StringTools.startsWith(arg, "test=")) {
				final testName = arg.substr(5);
				SpecificTests.push(testName);
			}
		}
		
		// Run tests
		final success = runTests();
		
		// Exit with appropriate code
		Sys.exit(success ? 0 : 1);
	}
	
	static function showHelp() {
		Sys.println("Reflaxe.Elixir Test Runner
		
Usage: haxe Test.hxml [options]

Options:
  help              Show this help message
  test=NAME         Run only the specified test (can be used multiple times)
  update-intended   Update the intended output files with current output
  show-output       Show compilation output even when successful
  no-details        Don't show detailed differences when output doesn't match

Examples:
  haxe Test.hxml                           # Run all tests
  haxe Test.hxml test=liveview_basic       # Run specific test
  haxe Test.hxml test=liveview test=otp    # Run multiple tests
  haxe Test.hxml update-intended           # Accept current output as correct
");
	}
	
	static function runTests(): Bool {
		// Get list of test directories
		var testDirs = getTestDirectories();
		
		// Filter if specific tests requested
		if (SpecificTests.length > 0) {
			testDirs = testDirs.filter(dir -> {
				for (test in SpecificTests) {
					if (dir.indexOf(test) >= 0) return true;
				}
				return false;
			});
			
			if (testDirs.length == 0) {
				Sys.println('ERROR: No tests found matching: ${SpecificTests.join(", ")}');
				return false;
			}
		}
		
		Sys.println('Running ${testDirs.length} test(s)...\n');
		
		var failures = 0;
		var successes = 0;
		
		for (testDir in testDirs) {
			if (runTest(testDir)) {
				successes++;
			} else {
				failures++;
			}
		}
		
		// Print summary
		Sys.println('\n' + StringTools.rpad("", "=", 50));
		Sys.println('Test Results: ${successes}/${testDirs.length} passed');
		
		if (failures > 0) {
			Sys.println('FAILED: $failures test(s) failed');
		} else {
			Sys.println('SUCCESS: All tests passed! ✅');
		}
		
		return failures == 0;
	}
	
	static function getTestDirectories(): Array<String> {
		if (!sys.FileSystem.exists(TEST_DIR)) {
			Sys.println('Test directory not found: $TEST_DIR');
			return [];
		}
		
		final dirs = [];
		for (item in sys.FileSystem.readDirectory(TEST_DIR)) {
			final path = haxe.io.Path.join([TEST_DIR, item]);
			if (sys.FileSystem.isDirectory(path)) {
				// Check if it has a compile.hxml file
				if (sys.FileSystem.exists(haxe.io.Path.join([path, "compile.hxml"]))) {
					dirs.push(item);
				}
			}
		}
		
		dirs.sort((a, b) -> a < b ? -1 : 1);
		return dirs;
	}
	
	static function runTest(testName: String): Bool {
		Sys.println('Testing: $testName');
		Sys.println(StringTools.rpad("", "-", 40));
		
		final testPath = haxe.io.Path.join([TEST_DIR, testName]);
		final hxmlPath = haxe.io.Path.join([testPath, "compile.hxml"]);
		final outPath = haxe.io.Path.join([testPath, UpdateIntended ? INTENDED_DIR : OUT_DIR]);
		
		// Check if compile.hxml exists
		if (!sys.FileSystem.exists(hxmlPath)) {
			Sys.println('  ❌ Missing compile.hxml');
			return false;
		}
		
		// Build compilation arguments
		final args = [
			"-cp", "src",
			"-cp", "std",
			"-cp", testPath,
			"-lib", "reflaxe",
			"--macro", "reflaxe.elixir.CompilerInit.Start()",
			"-D", 'elixir_output=$outPath',
			hxmlPath
		];
		
		// Run Haxe compiler
		if (ShowAllOutput) {
			Sys.println('  Command: haxe ${args.join(" ")}');
		}
		
		final process = new sys.io.Process("haxe", args);
		final stdout = process.stdout.readAll().toString();
		final stderr = process.stderr.readAll().toString();
		final exitCode = process.exitCode();
		process.close();
		
		// Check compilation result
		if (exitCode != 0) {
			Sys.println('  ❌ Compilation failed (exit code: $exitCode)');
			if (stdout.length > 0) Sys.println('  Output: $stdout');
			if (stderr.length > 0) Sys.println('  Error: $stderr');
			return false;
		}
		
		if (ShowAllOutput && stdout.length > 0) {
			Sys.println('  Output: $stdout');
		}
		
		// If updating intended, we're done
		if (UpdateIntended) {
			Sys.println('  ✅ Updated intended output');
			return true;
		}
		
		// Compare output with intended
		final intendedPath = haxe.io.Path.join([testPath, INTENDED_DIR]);
		
		if (!sys.FileSystem.exists(intendedPath)) {
			Sys.println('  ⚠️  No intended output found (run with update-intended to create)');
			return false;
		}
		
		// Compare all files
		final differences = compareDirectories(outPath, intendedPath);
		
		if (differences.length > 0) {
			Sys.println('  ❌ Output does not match intended:');
			if (!NoDetails) {
				for (diff in differences) {
					Sys.println('    - $diff');
				}
			} else {
				Sys.println('    (${differences.length} difference(s) - use show-output for details)');
			}
			return false;
		}
		
		Sys.println('  ✅ Output matches intended');
		return true;
	}
	
	static function compareDirectories(actualDir: String, intendedDir: String): Array<String> {
		final differences = [];
		
		// Get all files from intended directory
		final intendedFiles = getAllFiles(intendedDir);
		final actualFiles = getAllFiles(actualDir);
		
		// Check each intended file exists and matches
		for (file in intendedFiles) {
			final intendedPath = haxe.io.Path.join([intendedDir, file]);
			final actualPath = haxe.io.Path.join([actualDir, file]);
			
			if (!sys.FileSystem.exists(actualPath)) {
				differences.push('Missing file: $file');
				continue;
			}
			
			// Compare file contents
			final intendedContent = normalizeContent(sys.io.File.getContent(intendedPath));
			final actualContent = normalizeContent(sys.io.File.getContent(actualPath));
			
			if (intendedContent != actualContent) {
				differences.push('Content differs: $file');
				
				if (!NoDetails && ShowAllOutput) {
					// Show detailed diff
					showDiff(file, intendedContent, actualContent);
				}
			}
		}
		
		// Check for extra files in actual output
		for (file in actualFiles) {
			if (!intendedFiles.contains(file)) {
				differences.push('Extra file: $file');
			}
		}
		
		return differences;
	}
	
	static function getAllFiles(dir: String, prefix: String = ""): Array<String> {
		if (!sys.FileSystem.exists(dir)) return [];
		
		final files = [];
		for (item in sys.FileSystem.readDirectory(dir)) {
			final path = haxe.io.Path.join([dir, item]);
			final relPath = prefix.length > 0 ? haxe.io.Path.join([prefix, item]) : item;
			
			if (sys.FileSystem.isDirectory(path)) {
				// Recursively get files from subdirectories
				for (subFile in getAllFiles(path, relPath)) {
					files.push(subFile);
				}
			} else {
				files.push(relPath);
			}
		}
		return files;
	}
	
	static function normalizeContent(content: String): String {
		// Normalize line endings and trim whitespace
		return StringTools.trim(StringTools.replace(content, "\r\n", "\n"));
	}
	
	static function showDiff(file: String, intended: String, actual: String) {
		Sys.println('    Diff for $file:');
		
		final intendedLines = intended.split("\n");
		final actualLines = actual.split("\n");
		
		final maxLines = Std.int(Math.max(intendedLines.length, actualLines.length));
		
		for (i in 0...Std.int(Math.min(maxLines, 10))) { // Show first 10 different lines
			final intendedLine = i < intendedLines.length ? intendedLines[i] : "<missing>";
			final actualLine = i < actualLines.length ? actualLines[i] : "<missing>";
			
			if (intendedLine != actualLine) {
				Sys.println('      Line ${i + 1}:');
				Sys.println('        Expected: $intendedLine');
				Sys.println('        Actual:   $actualLine');
			}
		}
		
		if (maxLines > 10) {
			Sys.println('      ... and ${maxLines - 10} more lines');
		}
	}
}