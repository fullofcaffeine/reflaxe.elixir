package reflaxe.elixir.test;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr.Position;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;

/**
 * TestProgressTracker: Incremental test execution and progress reporting for Reflaxe.Elixir
 *
 * WHY: Enables efficient test-driven development by tracking which tests have been
 * compiled, which have changed, and which need re-execution. Integrates with the
 * test runner infrastructure to provide real-time feedback during compilation.
 *
 * WHAT: Provides test tracking capabilities:
 * - Monitors test compilation progress
 * - Detects changes requiring re-compilation
 * - Reports test results in real-time
 * - Maintains test execution history
 * - Integrates with incremental compilation
 * - Generates test manifests for runner
 *
 * HOW: Hooks into the compilation pipeline:
 * - Tracks each test as it's compiled
 * - Writes progress to shared state file
 * - Communicates with test runner via filesystem
 * - Uses fingerprinting to detect changes
 * - Maintains cache of previous results
 *
 * ARCHITECTURE BENEFITS:
 * - Performance: Only re-run changed tests
 * - Feedback: Real-time progress during compilation
 * - Integration: Works with existing test infrastructure
 * - Reliability: Persistent state across runs
 * - Debugging: Detailed logs of test execution
 *
 * EDGE CASES:
 * - Concurrent test execution
 * - Partial compilation failures
 * - State file corruption
 * - Cross-platform path handling
 *
 * @see ElixirASTContext for integration point
 * @see scripts/test-runner.sh for consumer
 */
class TestProgressTracker {
    /**
     * Path to test results file
     * Shared with test runner for coordination
     */
    static final TEST_RESULTS_FILE = ".test-progress.json";

    /**
     * Path to test manifest
     * Lists all tests to be executed
     */
    static final TEST_MANIFEST_FILE = ".test-manifest.json";

    /**
     * Current test being compiled
     */
    var currentTest: Null<TestInfo> = null;

    /**
     * All tests processed in this compilation
     */
    var processedTests: Map<String, TestInfo> = new Map();

    /**
     * Test fingerprints for change detection
     */
    var testFingerprints: Map<String, String> = new Map();

    /**
     * Start time of compilation
     */
    var startTime: Float;

    /**
     * Output directory for test results
     */
    var outputDir: String;

    /**
     * Constructor
     *
     * @param outputDir Directory for test output files
     */
    public function new(?outputDir: String) {
        this.outputDir = outputDir != null ? outputDir : ".";
        this.startTime = Sys.time();
        loadPreviousResults();
    }

    /**
     * Mark the start of a test compilation
     *
     * @param testPath Path to test being compiled
     * @param testName Name of the test
     */
    public function startTest(testPath: String, testName: String): Void {
        currentTest = {
            path: testPath,
            name: testName,
            status: InProgress,
            startTime: Sys.time(),
            endTime: null,
            errors: [],
            warnings: [],
            fingerprint: computeFingerprint(testPath)
        };

        processedTests.set(testPath, currentTest);
        writeProgress();
    }

    /**
     * Mark the successful completion of a test compilation
     */
    public function completeTest(): Void {
        if (currentTest != null) {
            currentTest.status = Success;
            currentTest.endTime = Sys.time();
            writeProgress();
            currentTest = null;
        }
    }

    /**
     * Mark a test compilation as failed
     *
     * @param error Error message
     * @param pos Source position of error
     */
    public function failTest(error: String, ?pos: Position): Void {
        if (currentTest != null) {
            currentTest.status = Failed;
            currentTest.endTime = Sys.time();
            currentTest.errors.push({
                message: error,
                position: pos != null ? positionToString(pos) : null
            });
            writeProgress();
            currentTest = null;
        }
    }

    /**
     * Add a warning to the current test
     *
     * @param warning Warning message
     * @param pos Source position
     */
    public function addWarning(warning: String, ?pos: Position): Void {
        if (currentTest != null) {
            currentTest.warnings.push({
                message: warning,
                position: pos != null ? positionToString(pos) : null
            });
        }
    }

    /**
     * Check if a test needs recompilation
     *
     * @param testPath Path to test
     * @return True if test has changed
     */
    public function needsRecompilation(testPath: String): Bool {
        var newFingerprint = computeFingerprint(testPath);

        if (!testFingerprints.exists(testPath)) {
            return true;
        }

        return testFingerprints.get(testPath) != newFingerprint;
    }

    /**
     * Get tests that have changed since last run
     *
     * @param testPaths All test paths
     * @return Array of changed test paths
     */
    public function getChangedTests(testPaths: Array<String>): Array<String> {
        var changed = [];

        for (path in testPaths) {
            if (needsRecompilation(path)) {
                changed.push(path);
            }
        }

        return changed;
    }

    /**
     * Generate test manifest for runner
     *
     * @param tests Array of test information
     */
    public function generateManifest(tests: Array<TestInfo>): Void {
        var manifest = {
            version: "1.0",
            timestamp: Date.now().toString(),
            totalTests: tests.length,
            tests: tests.map(t -> {
                path: t.path,
                name: t.name,
                category: extractCategory(t.path),
                needsRecompilation: needsRecompilation(t.path)
            })
        };

        var manifestPath = haxe.io.Path.join([outputDir, TEST_MANIFEST_FILE]);
        File.saveContent(manifestPath, Json.stringify(manifest, null, "  "));
    }

    /**
     * Write current progress to file
     */
    function writeProgress(): Void {
        var progress = {
            timestamp: Date.now().toString(),
            elapsed: Sys.time() - startTime,
            total: Lambda.count(processedTests),
            completed: Lambda.count(processedTests, t -> t.status == Success),
            failed: Lambda.count(processedTests, t -> t.status == Failed),
            inProgress: Lambda.count(processedTests, t -> t.status == InProgress),
            tests: Lambda.array(processedTests)
        };

        var progressPath = haxe.io.Path.join([outputDir, TEST_RESULTS_FILE]);
        File.saveContent(progressPath, Json.stringify(progress, null, "  "));
    }

    /**
     * Load previous test results
     */
    function loadPreviousResults(): Void {
        var resultsPath = haxe.io.Path.join([outputDir, TEST_RESULTS_FILE]);

        if (FileSystem.exists(resultsPath)) {
            try {
                var content = File.getContent(resultsPath);
                var data = Json.parse(content);

                if (data.tests != null) {
                    for (test in (data.tests : Array<Dynamic>)) {
                        if (test.fingerprint != null) {
                            testFingerprints.set(test.path, test.fingerprint);
                        }
                    }
                }
            } catch (e: Dynamic) {
                // Ignore corrupted file, start fresh
            }
        }
    }

    /**
     * Compute fingerprint for a test file
     *
     * @param testPath Path to test
     * @return Fingerprint string
     */
    function computeFingerprint(testPath: String): String {
        if (!FileSystem.exists(testPath)) {
            return "";
        }

        try {
            var stat = FileSystem.stat(testPath);
            var content = File.getContent(testPath);

            // Simple fingerprint: size + modification time + content hash
            var hash = haxe.crypto.Md5.encode(content);
            return '${stat.size}_${stat.mtime.getTime()}_${hash}';
        } catch (e: Dynamic) {
            return "";
        }
    }

    /**
     * Extract test category from path
     *
     * @param testPath Test file path
     * @return Category name
     */
    function extractCategory(testPath: String): String {
        // Extract category from path like test/snapshot/core/arrays/Main.hx
        var parts = testPath.split("/");

        for (i in 0...parts.length) {
            if (parts[i] == "snapshot" && i + 1 < parts.length) {
                return parts[i + 1];
            }
        }

        return "uncategorized";
    }

    /**
     * Convert position to string representation
     *
     * @param pos Source position
     * @return String representation
     */
    function positionToString(pos: Position): String {
        var info = Context.getPosInfos(pos);
        return '${info.file}:${info.min}-${info.max}';
    }

    /**
     * Get summary statistics
     *
     * @return Summary object
     */
    public function getSummary(): TestSummary {
        return {
            totalTests: Lambda.count(processedTests),
            successful: Lambda.count(processedTests, t -> t.status == Success),
            failed: Lambda.count(processedTests, t -> t.status == Failed),
            inProgress: Lambda.count(processedTests, t -> t.status == InProgress),
            totalTime: Sys.time() - startTime,
            changedTests: Lambda.count(processedTests, t ->
                testFingerprints.get(t.path) != t.fingerprint
            )
        };
    }

    /**
     * Clean up and finalize tracking
     */
    public function finalize(): Void {
        // Mark any in-progress tests as failed
        for (test in processedTests) {
            if (test.status == InProgress) {
                test.status = Failed;
                test.errors.push({
                    message: "Test compilation did not complete",
                    position: null
                });
            }
        }

        writeProgress();
    }
}

/**
 * Test information structure
 */
typedef TestInfo = {
    var path: String;
    var name: String;
    var status: TestStatus;
    var startTime: Float;
    var endTime: Null<Float>;
    var errors: Array<TestError>;
    var warnings: Array<TestWarning>;
    var fingerprint: String;
}

/**
 * Test execution status
 */
enum TestStatus {
    InProgress;
    Success;
    Failed;
}

/**
 * Test error information
 */
typedef TestError = {
    var message: String;
    var position: Null<String>;
}

/**
 * Test warning information
 */
typedef TestWarning = {
    var message: String;
    var position: Null<String>;
}

/**
 * Test summary statistics
 */
typedef TestSummary = {
    var totalTests: Int;
    var successful: Int;
    var failed: Int;
    var inProgress: Int;
    var totalTime: Float;
    var changedTests: Int;
}

#end