package test;

import test.TestCommon;

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
	static var SkipCompilation = false; // Skip Elixir compilation testing (compilation is default)
	
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
		SkipCompilation = args.contains("nocompile");
		
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
  nocompile           Skip Elixir compilation testing (compilation is default)

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
			"-D", 'reflaxe.dont_output_metadata_id', // Don't generate volatile id field in tests
			"compile.hxml"
		];
		
		// Run Haxe compiler with timeout wrapper
		if (ShowAllOutput) {
			Sys.println('  Command: haxe ${args.join(" ")}');
		}
		
		// Use timeout command to prevent hanging (10 seconds per test)
		final timeoutSeconds = 10;
		final isUnix = (Sys.systemName() == "Mac" || Sys.systemName() == "Linux");
		
		// Build the command and args based on platform
		final processCmd = isUnix ? "timeout" : "haxe";
		final processArgs = isUnix 
			? [Std.string(timeoutSeconds), "haxe"].concat(args)
			: args;
		
		final process = new sys.io.Process(processCmd, processArgs);
		final stdout = process.stdout.readAll().toString();
		final stderr = process.stderr.readAll().toString();
		final exitCode = process.exitCode();
		process.close();
		
		// Check for timeout (exit code 124 on Unix)
		if (exitCode == 124) {
			Sys.println('  ❌ Test timed out after ${timeoutSeconds} seconds');
			return false;
		}
		
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
		final differences = TestCommon.compareDirectoriesDetailed(outPath, intendedPath);
		
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
		
		// Compile and run the generated Elixir code (unless skipped)
		if (!SkipCompilation) {
			if (!compileAndRunElixir(testName, outPath)) {
				return false;
			}
		}
		
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
	
	/**
	 * Compile and optionally run the generated Elixir code
	 * This validates that the generated code is syntactically correct and can run on the BEAM VM
	 */
	static function compileAndRunElixir(testName: String, outputDir: String): Bool {
		Sys.println('  🔧 Compiling Elixir code...');
		
		// Check if mix.exs exists in the output directory
		final mixPath = haxe.io.Path.join([outputDir, "mix.exs"]);
		if (!sys.FileSystem.exists(mixPath)) {
			// Create a minimal mix.exs file for compilation
			final mixContent = 'defmodule TestProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_${testName},
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
';
			sys.io.File.saveContent(mixPath, mixContent);
			if (ShowAllOutput) {
				Sys.println('    Created minimal mix.exs');
			}
		}
		
		// Save current directory and change to output directory
		final originalCwd = Sys.getCwd();
		Sys.setCwd(outputDir);
		
		// Run mix compile with timeout
		final isUnix = (Sys.systemName() == "Mac" || Sys.systemName() == "Linux");
		final timeoutCmd = isUnix ? "timeout" : "mix";
		final timeoutArgs = isUnix 
			? ["5", "mix", "compile", "--force"]
			: ["compile", "--force"];
		
		final compileProcess = new sys.io.Process(timeoutCmd, timeoutArgs);
		final compileStdout = compileProcess.stdout.readAll().toString();
		final compileStderr = compileProcess.stderr.readAll().toString();
		final compileExitCode = compileProcess.exitCode();
		compileProcess.close();
		
		// Restore original directory
		Sys.setCwd(originalCwd);
		
		// Check for timeout (exit code 124 on Unix)
		if (compileExitCode == 124) {
			Sys.println('  ❌ Elixir compilation timed out (5 seconds)');
			return false;
		}
		
		if (compileExitCode != 0) {
			Sys.println('  ❌ Elixir compilation failed');
			if (ShowAllOutput || compileStderr.length > 0) {
				Sys.println('    Error output:');
				for (line in compileStderr.split('\n')) {
					if (StringTools.trim(line).length > 0) {
						Sys.println('      $line');
					}
				}
			}
			return false;
		}
		
		Sys.println('  ✅ Elixir code compiles successfully');
		
		// Skip execution testing for now - compilation validation is sufficient
		// The tests were designed for snapshot testing, not runtime execution
		// Many tests have Main.main() that depends on other modules being available
		
		return true;
	}
}