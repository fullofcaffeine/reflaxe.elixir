package test;

import sys.io.Process;

/**
 * Simple Test Runner - Sequential version for debugging
 * 
 * This is a simplified version of ParallelTestRunner to debug the hanging issue.
 * Once this works, we can enhance it to support parallel execution.
 */
class SimpleParallelTest {
    static final TEST_DIR = "test/tests";
    static final OUT_DIR = "out";
    static final INTENDED_DIR = "intended";
    
    public static function main() {
        final args = Sys.args();
        
        if (args.contains("help")) {
            Sys.println("Simple Test Runner - Sequential Debug Version");
            return;
        }
        
        // Parse specific tests
        var specificTests: Array<String> = [];
        for (arg in args) {
            if (StringTools.startsWith(arg, "test=")) {
                final testName = arg.substr(5);
                specificTests.push(testName);
            }
        }
        
        // Get test directories
        var testDirs = getTestDirectories();
        
        // Filter if specific tests requested
        if (specificTests.length > 0) {
            testDirs = testDirs.filter(dir -> {
                for (test in specificTests) {
                    if (dir.indexOf(test) >= 0) return true;
                }
                return false;
            });
        }
        
        Sys.println('Running ${testDirs.length} test(s) sequentially...\n');
        
        var successes = 0;
        var failures = 0;
        
        for (testDir in testDirs) {
            Sys.println('Testing: $testDir');
            
            if (runSingleTest(testDir)) {
                Sys.println('  ✅ PASSED');
                successes++;
            } else {
                Sys.println('  ❌ FAILED');
                failures++;
            }
        }
        
        Sys.println('\n==================================================');
        Sys.println('Test Results: ${successes}/${testDirs.length} passed');
        
        if (failures == 0) {
            Sys.println('SUCCESS: All tests passed! ✅');
        } else {
            Sys.println('FAILED: $failures test(s) failed');
        }
        
        Sys.exit(failures == 0 ? 0 : 1);
    }
    
    static function runSingleTest(testName: String): Bool {
        final testPath = haxe.io.Path.join([TEST_DIR, testName]);
        final hxmlPath = haxe.io.Path.join([testPath, "compile.hxml"]);
        
        if (!sys.FileSystem.exists(hxmlPath)) {
            Sys.println('    Missing compile.hxml');
            return false;
        }
        
        // Save current directory and change to test directory
        final originalCwd = Sys.getCwd();
        
        try {
            Sys.setCwd(testPath);
            
            // Run compilation
            final args = ["-D", "elixir_output=out", "compile.hxml"];
            final process = new Process("haxe", args);
            final stdout = process.stdout.readAll().toString();
            final stderr = process.stderr.readAll().toString();
            final exitCode = process.exitCode();
            process.close();
            
            // Restore directory
            Sys.setCwd(originalCwd);
            
            // Check result
            if (exitCode != 0) {
                Sys.println('    Compilation failed (exit code: $exitCode)');
                if (stderr.length > 0) Sys.println('    Error: $stderr');
                return false;
            }
            
            // Compare output with intended (simplified)
            final outPath = haxe.io.Path.join([testPath, OUT_DIR]);
            final intendedPath = haxe.io.Path.join([testPath, INTENDED_DIR]);
            
            if (!sys.FileSystem.exists(intendedPath)) {
                Sys.println('    No intended output found');
                return false;
            }
            
            // Simple file count comparison for now
            if (!sys.FileSystem.exists(outPath)) {
                Sys.println('    No output generated');
                return false;
            }
            
            return true;
            
        } catch (e: Dynamic) {
            Sys.setCwd(originalCwd);
            Sys.println('    Exception: $e');
            return false;
        }
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
}