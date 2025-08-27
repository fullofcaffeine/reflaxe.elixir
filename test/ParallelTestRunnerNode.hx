package test;

import js.node.ChildProcess;
import js.node.Fs;
import js.node.Path;
import js.node.Buffer;
import js.lib.Promise;
import js.Syntax;
import js.Node.console;
import test.TestCommon;

using StringTools;

/**
 * ParallelTestRunnerNode: Node.js-based parallel test execution
 * 
 * WHY: The eval target has limited process management capabilities causing deadlocks
 * and hanging processes. Node.js provides mature async process APIs that handle
 * parallel execution reliably without file locking or directory change issues.
 * 
 * WHAT: Spawns multiple haxe compiler processes in parallel using Node.js
 * child_process API, collecting results asynchronously without blocking.
 * 
 * HOW: Uses Promise-based async patterns with proper event handling for
 * process lifecycle management. Each test runs in its own child process
 * with proper working directory configuration and stream-based output capture.
 * 
 * ARCHITECTURE BENEFITS:
 * - No file locking needed (each process is independent)
 * - True async I/O (non-blocking process management)
 * - Reliable timeout handling (Node.js timer APIs)
 * - Cross-platform consistency (Node.js abstracts OS differences)
 * 
 * FUTURE: Once this test runner is stable, we could abstract the Node.js-specific
 * APIs and compile this to Elixir using our own Reflaxe.Elixir target! This would
 * allow us to dogfood our compiler and run tests using Elixir's excellent
 * concurrency primitives (GenServer, Task.async_stream, etc). The abstraction
 * would map: ChildProcess.spawn -> System.cmd, Promises -> Tasks, etc.
 * 
 * TODO: Convert Promise chains to async/await syntax using our reflaxe.js.Async
 * library (std/reflaxe/js/Async.hx). This would make the code cleaner:
 * ```haxe
 * @:async static function runTestsParallel(tests): Array<TestResult> {
 *     var results = [];
 *     for (batch in batches) {
 *         var batchResults = await(Promise.all(batch.map(runSingleTest)));
 *         results = results.concat(batchResults);
 *     }
 *     return results;
 * }
 * ```
 */
class ParallelTestRunnerNode {
    // Constants
    static final TEST_DIR = "test/tests";
    static final WORKER_COUNT = 4;  // Reduced to 4 to avoid resource contention with compilation
    static final TIMEOUT_MS = 30000; // 30 seconds per test
    
    // Configuration flags
    static var updateIntended = false;
    static var specificTests: Array<String> = [];
    static var showOutput = false;
    static var noDetails = false;
    
    // Test tracking
    static var totalTests = 0;
    static var completedTests = 0;
    static var failedTests: Array<String> = [];
    
    static function main() {
        // Parse command line arguments
        final args: Array<String> = Syntax.code("process.argv.slice(2)");
        
        for (arg in args) {
            if (arg == "update-intended") {
                updateIntended = true;
            } else if (arg.startsWith("test=")) {
                specificTests.push(arg.substr(5));
            } else if (arg == "show-output") {
                showOutput = true;
            } else if (arg == "no-details") {
                noDetails = true;
            } else if (arg == "help") {
                showHelp();
                return;
            }
        }
        
        // Get test directories
        final tests = specificTests.length > 0 ? specificTests : getTestDirectories();
        totalTests = tests.length;
        
        console.log('\n🚀 Running ${totalTests} test(s) with up to ${WORKER_COUNT} parallel workers...');
        if (totalTests > 20) {
            final estimatedTime = Math.ceil((totalTests / WORKER_COUNT) * 5);
            console.log('⏱️  Estimated time: ~${estimatedTime} seconds (compilation takes time)\n');
        } else {
            console.log('');
        }
        
        // Run tests in parallel
        runTestsParallel(tests).then(results -> {
            printResults(results);
            final exitCode = failedTests.length > 0 ? 1 : 0;
            Syntax.code("process.exit({0})", exitCode);
        }).catchError(err -> {
            console.error('❌ ERROR:', err);
            Syntax.code("process.exit(1)");
        });
    }
    
    static function showHelp() {
        console.log("\n📚 Reflaxe.Elixir Parallel Test Runner (Node.js)

Usage: node parallel-runner.js [options]

Options:
  help                Show this help message
  test=NAME           Run only the specified test
  update-intended     Update the intended output files
  show-output         Show compilation output
  no-details          Don't show detailed differences

Examples:
  node parallel-runner.js                    # Run all tests
  node parallel-runner.js test=arrays        # Run specific test
  node parallel-runner.js update-intended    # Update intended outputs\n");
    }
    
    /**
     * Run tests in parallel using Promise-based async execution
     */
    static function runTestsParallel(tests: Array<String>): Promise<Array<TestResult>> {
        // Create batches for controlled parallelism
        final batches: Array<Array<String>> = [];
        var currentBatch: Array<String> = [];
        
        for (test in tests) {
            currentBatch.push(test);
            if (currentBatch.length >= WORKER_COUNT) {
                batches.push(currentBatch);
                currentBatch = [];
            }
        }
        if (currentBatch.length > 0) {
            batches.push(currentBatch);
        }
        
        // Process batches sequentially, tests within batch in parallel
        final allResults: Array<TestResult> = [];
        var promise = Promise.resolve(null);
        
        for (batch in batches) {
            promise = promise.then(_ -> {
                final batchPromises = batch.map(test -> runSingleTest(test));
                return Promise.all(batchPromises).then(results -> {
                    for (result in results) {
                        allResults.push(result);
                        completedTests++;
                        printProgress(result);
                    }
                    return null;
                });
            });
        }
        
        return promise.then(_ -> allResults);
    }
    
    /**
     * Run a single test using Node.js child_process.spawn
     */
    static function runSingleTest(testName: String): Promise<TestResult> {
        return new Promise((resolve, reject) -> {
            final testPath = Path.join(TEST_DIR, testName);
            final outputDir = updateIntended ? "intended" : "out";
            final startTime = Date.now().getTime();
            
            // Prepare haxe arguments
            final args = [
                "-D", 'elixir_output=$outputDir',
                "-D", "reflaxe.dont_output_metadata_id",
                "compile.hxml"
            ];
            
            // Spawn options with working directory
            final options: Dynamic = {
                cwd: testPath,
                timeout: TIMEOUT_MS,
                shell: false
            };
            
            var stdout = "";
            var stderr = "";
            var timedOut = false;
            
            // Spawn the haxe process
            final proc = ChildProcess.spawn("haxe", args, options);
            
            // Set up timeout handler
            final timeoutId = js.Node.setTimeout(() -> {
                timedOut = true;
                // Force kill the process and all children
                proc.kill('SIGKILL');  // Use SIGKILL for force termination
            }, TIMEOUT_MS);
            
            // Capture stdout
            proc.stdout.on("data", (data: Buffer) -> {
                stdout += data.toString();
            });
            
            // Capture stderr
            proc.stderr.on("data", (data: Buffer) -> {
                stderr += data.toString();
            });
            
            // Handle process close
            proc.on("close", (code: Int, signal: String) -> {
                js.Node.clearTimeout(timeoutId);
                final duration = Date.now().getTime() - startTime;
                
                if (timedOut) {
                    resolve({
                        name: testName,
                        success: false,
                        duration: duration,
                        message: 'Test timed out after ${TIMEOUT_MS}ms'
                    });
                } else if (code == 0) {
                    // Compilation succeeded
                    if (!updateIntended) {
                        // Compare output with intended
                        final success = compareOutput(testName);
                        resolve({
                            name: testName,
                            success: success,
                            duration: duration,
                            message: success ? null : "Output does not match intended"
                        });
                    } else {
                        // Update mode - always success
                        resolve({
                            name: testName,
                            success: true,
                            duration: duration,
                            message: null
                        });
                    }
                } else {
                    // Compilation failed
                    if (!failedTests.contains(testName)) {
                        failedTests.push(testName);
                    }
                    resolve({
                        name: testName,
                        success: false,
                        duration: duration,
                        message: 'Compilation failed (exit code: $code)\n$stderr'
                    });
                }
            });
            
            // Handle process error
            proc.on("error", (err: Dynamic) -> {
                js.Node.clearTimeout(timeoutId);
                final duration = Date.now().getTime() - startTime;
                if (!failedTests.contains(testName)) {
                    failedTests.push(testName);
                }
                resolve({
                    name: testName,
                    success: false,
                    duration: duration,
                    message: 'Process error: $err'
                });
            });
        });
    }
    
    /**
     * Compare test output with intended output
     */
    static function compareOutput(testName: String): Bool {
        final outDir = Path.join(TEST_DIR, testName, "out");
        final intendedDir = Path.join(TEST_DIR, testName, "intended");
        
        if (!Fs.existsSync(intendedDir)) {
            return false;
        }
        
        return compareDirectories(outDir, intendedDir);
    }
    
    /**
     * Compare two directories for identical content
     */
    static function compareDirectories(dir1: String, dir2: String): Bool {
        if (!Fs.existsSync(dir1) || !Fs.existsSync(dir2)) {
            return false;
        }
        
        // Get .ex files from both directories
        final files1 = Fs.readdirSync(dir1).filter((f: String) -> f.endsWith(".ex"));
        final files2 = Fs.readdirSync(dir2).filter((f: String) -> f.endsWith(".ex"));
        
        if (files1.length != files2.length) {
            return false;
        }
        
        // Sort for consistent comparison
        files1.sort((a, b) -> a < b ? -1 : 1);
        files2.sort((a, b) -> a < b ? -1 : 1);
        
        // Compare each file
        for (i in 0...files1.length) {
            if (files1[i] != files2[i]) {
                return false;
            }
            
            final content1 = Fs.readFileSync(Path.join(dir1, files1[i]), "utf8");
            final content2 = Fs.readFileSync(Path.join(dir2, files2[i]), "utf8");
            
            if (content1 != content2) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Get all test directories
     */
    static function getTestDirectories(): Array<String> {
        final items: Array<String> = Fs.readdirSync(TEST_DIR);
        final filtered = items.filter((item: String) -> {
            final path = Path.join(TEST_DIR, item);
            return Fs.statSync(path).isDirectory() && 
                   Fs.existsSync(Path.join(path, "compile.hxml"));
        });
        filtered.sort((a: String, b: String) -> a < b ? -1 : 1);
        return filtered;
    }
    
    /**
     * Generate a visual progress bar
     */
    static function generateProgressBar(percent: Int): String {
        final width = 20;
        final filled = Math.floor(width * percent / 100);
        final empty = width - filled;
        return '[' + StringTools.rpad('', '█', filled) + StringTools.rpad('', '░', empty) + ']';
    }
    
    /**
     * Print progress for a completed test
     */
    static function printProgress(result: TestResult) {
        final percent = Math.round((completedTests / totalTests) * 100);
        final status = result.success ? "✅" : "❌";
        final ms = Math.round(result.duration);
        final progressBar = generateProgressBar(percent);
        console.log('${progressBar} [${percent}%] ${status} ${result.name} (${ms}ms)');
        
        if (!result.success && result.message != null && showOutput && !noDetails) {
            final lines = result.message.split("\n");
            for (i in 0...Math.floor(Math.min(3, lines.length))) {
                console.log('    ${lines[i]}');
            }
            if (lines.length > 3) {
                console.log('    ... (${lines.length - 3} more lines)');
            }
        }
    }
    
    /**
     * Print final test results
     */
    static function printResults(results: Array<TestResult>) {
        final failed = results.filter(r -> !r.success);
        final passed = results.length - failed.length;
        
        console.log("\n" + StringTools.rpad("", "═", 50));
        console.log('📊 Test Results: ${passed}/${results.length} passed');
        
        var totalTime = 0.0;
        for (r in results) {
            totalTime += r.duration;
        }
        console.log('⏱️  Total Time: ${Math.round(totalTime / 1000)}s');
        
        if (failed.length > 0) {
            console.log('\n❌ FAILED: ${failed.length} test(s)');
            for (test in failed) {
                console.log('  • ${test.name}');
                if (test.message != null && !showOutput) {
                    // Show first line of error if not already shown
                    final firstLine = test.message.split("\n")[0];
                    if (firstLine.length > 0) {
                        console.log('    ${firstLine.substr(0, 80)}${firstLine.length > 80 ? "..." : ""}');
                    }
                }
            }
        } else {
            console.log('\n✅ SUCCESS: All tests passed! 🎉');
        }
        
        // Performance comparison
        final sequentialEstimate = results.length * 3.7; // Estimated sequential time
        final speedup = Math.round((sequentialEstimate - (totalTime / 1000)) / sequentialEstimate * 100);
        if (speedup > 0) {
            console.log('⚡ Performance: ~${speedup}% faster than sequential execution');
        }
    }
}

/**
 * Test result structure
 */
typedef TestResult = {
    name: String,
    success: Bool,
    duration: Float,
    ?message: String
}