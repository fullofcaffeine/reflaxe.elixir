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
	static var FlexiblePositions = false;
	
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
		FlexiblePositions = args.contains("flexible-positions");
		
		// Parse specific tests
		for (arg in args) {
			if (StringTools.startsWith(arg, "test=")) {
				final testName = arg.substr(5);
				SpecificTests.push(testName);
			} else if (arg.indexOf("-") == -1 && arg != "help" && sys.FileSystem.exists(haxe.io.Path.join([TEST_DIR, arg]))) {
				// Also accept test names without "test=" prefix
				SpecificTests.push(arg);
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
  help                Show this help message
  test=NAME           Run only the specified test (can be used multiple times)
  update-intended     Update the intended output files with current output
  show-output         Show compilation output even when successful
  no-details          Don't show detailed differences when output doesn't match
  flexible-positions  Strip position info from stderr comparison (less brittle tests)

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
		final outPath = haxe.io.Path.join([testPath, OUT_DIR]);
		
		// Check if compile.hxml exists
		if (!sys.FileSystem.exists(hxmlPath)) {
			Sys.println('  ❌ Missing compile.hxml');
			return false;
		}
		
		// Save current directory and change to test directory
		final originalCwd = Sys.getCwd();
		Sys.setCwd(testPath);
		
		// Build compilation arguments
		// The compile.hxml should be self-contained, we just add the output directory
		// Since we changed to the test directory, use relative path
		final relativeOutPath = UpdateIntended ? INTENDED_DIR : OUT_DIR;
		final args = [
			"-D", 'elixir_output=$relativeOutPath',
			"compile.hxml"
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
		
		// Restore original directory
		Sys.setCwd(originalCwd);
		
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
		
		// Check stderr validation (for compile-time warning/error tests)
		if (!validateStderr(testPath, stderr)) {
			return false;
		}
		
		// If updating intended, copy out to intended
		if (UpdateIntended) {
			final intendedPath = haxe.io.Path.join([testPath, INTENDED_DIR]);
			
			// Create intended directory if it doesn't exist
			if (!sys.FileSystem.exists(intendedPath)) {
				sys.FileSystem.createDirectory(intendedPath);
			}
			
			// Copy all files from out to intended
			copyDirectory(outPath, intendedPath);
			
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
	
	/**
	 * Copy all files from source directory to destination directory
	 */
	static function copyDirectory(sourcePath: String, destPath: String): Void {
		if (!sys.FileSystem.exists(sourcePath)) return;
		
		// Ensure destination directory exists
		if (!sys.FileSystem.exists(destPath)) {
			sys.FileSystem.createDirectory(destPath);
		}
		
		// Copy all files from source to destination
		for (file in sys.FileSystem.readDirectory(sourcePath)) {
			final sourceFile = haxe.io.Path.join([sourcePath, file]);
			final destFile = haxe.io.Path.join([destPath, file]);
			
			if (sys.FileSystem.isDirectory(sourceFile)) {
				// Recursively copy subdirectories
				copyDirectory(sourceFile, destFile);
			} else {
				// Copy regular file
				sys.io.File.copy(sourceFile, destFile);
			}
		}
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
			final intendedContent = normalizeContent(sys.io.File.getContent(intendedPath), file);
			final actualContent = normalizeContent(sys.io.File.getContent(actualPath), file);
			
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
	
	static function normalizeContent(content: String, fileName: String = ""): String {
		// Normalize line endings and trim whitespace
		var normalized = StringTools.trim(StringTools.replace(content, "\r\n", "\n"));
		
		// Special handling for _GeneratedFiles.json - ignore the id field which increments on each build
		if (fileName == "_GeneratedFiles.json") {
			if (ShowAllOutput) {
				Sys.println('    [DEBUG] Processing _GeneratedFiles.json - removing id field');
			}
			// Parse as JSON and remove the id field for comparison
			try {
				var lines = normalized.split("\n");
				var filteredLines = [];
				var idRegex = ~/^\s*"id"\s*:\s*\d+,?$/;
				for (line in lines) {
					// Skip the id line (with or without trailing comma)
					if (!idRegex.match(line)) {
						filteredLines.push(line);
					} else if (ShowAllOutput) {
						Sys.println('    [DEBUG] Skipping id line: $line');
					}
				}
				normalized = filteredLines.join("\n");
			} catch (e: Dynamic) {
				// If parsing fails, use original normalized content
				if (ShowAllOutput) {
					Sys.println('    [DEBUG] Failed to process _GeneratedFiles.json: $e');
				}
			}
		}
		
		return normalized;
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
	
	/**
	 * Validate stderr output against expected_stderr.txt file
	 * Returns true if validation passes, false otherwise
	 */
	static function validateStderr(testPath: String, actualStderr: String): Bool {
		// Choose expected stderr file based on flexible positions flag
		var expectedStderrPath = haxe.io.Path.join([testPath, "expected_stderr.txt"]);
		if (FlexiblePositions) {
			final flexiblePath = haxe.io.Path.join([testPath, "expected_stderr_flexible.txt"]);
			if (sys.FileSystem.exists(flexiblePath)) {
				expectedStderrPath = flexiblePath;
			}
		}
		
		// If no expected_stderr.txt file exists, skip validation
		if (!sys.FileSystem.exists(expectedStderrPath)) {
			return true;
		}
		
		final expectedStderr = normalizeStderr(sys.io.File.getContent(expectedStderrPath));
		final normalizedActualStderr = normalizeStderr(actualStderr);
		
		if (expectedStderr != normalizedActualStderr) {
			Sys.println('  ❌ Stderr output does not match expected:');
			if (!NoDetails) {
				Sys.println('    Expected stderr:');
				if (expectedStderr.length == 0) {
					Sys.println('      (no warnings/errors expected)');
				} else {
					for (line in expectedStderr.split('\n')) {
						if (StringTools.trim(line).length > 0) {
							Sys.println('      $line');
						}
					}
				}
				Sys.println('    Actual stderr:');
				if (normalizedActualStderr.length == 0) {
					Sys.println('      (no warnings/errors)');
				} else {
					for (line in normalizedActualStderr.split('\n')) {
						if (StringTools.trim(line).length > 0) {
							Sys.println('      $line');
						}
					}
				}
			}
			return false;
		}
		
		if (ShowAllOutput) {
			if (expectedStderr.length > 0) {
				Sys.println('  ✅ Stderr validation passed (expected warnings found)');
			} else {
				Sys.println('  ✅ Stderr validation passed (no warnings as expected)');
			}
		}
		
		return true;
	}
	
	/**
	 * Normalize stderr content for comparison
	 * Removes empty lines, comments, and trims whitespace
	 * With flexible positions, also strips file position information
	 */
	static function normalizeStderr(content: String): String {
		final lines = content.split('\n');
		final normalizedLines = [];
		
		for (line in lines) {
			final trimmed = StringTools.trim(line);
			// Skip empty lines and comment lines (starting with #)
			if (trimmed.length > 0 && !StringTools.startsWith(trimmed, '#')) {
				var processedLine = trimmed;
				
				// If flexible positions is enabled, strip position information
				if (FlexiblePositions) {
					processedLine = stripPositionInfo(processedLine);
				}
				
				normalizedLines.push(processedLine);
			}
		}
		
		return normalizedLines.join('\n');
	}
	
	/**
	 * Strip position information from compiler output line
	 * Converts: "Main.hx:39: lines 39-41 : Warning : Message"
	 * To: "Warning : Message"
	 */
	static function stripPositionInfo(line: String): String {
		// Pattern to match: filename:line: lines start-end : Level : Message
		// We want to extract just "Level : Message"
		final warningPattern = ~/^.*?:\s*lines?\s*\d+(-\d+)?\s*:\s*(Warning|Error|Info)\s*:\s*(.*)$/;
		
		if (warningPattern.match(line)) {
			final level = warningPattern.matched(2);
			final message = warningPattern.matched(3);
			return '$level : $message';
		}
		
		// If pattern doesn't match, return the line as-is
		return line;
	}
}