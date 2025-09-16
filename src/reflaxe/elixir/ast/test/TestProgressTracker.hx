package reflaxe.elixir.ast.test;

#if (macro || reflaxe_runtime)

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

/**
 * TestProgressTracker: Incremental test execution system for modular builders
 *
 * WHY: As recommended by Codex, we need a way to track test progress incrementally,
 * especially when working on specific builders. This prevents re-running all tests
 * when only working on pattern matching or loop compilation.
 *
 * WHAT: Provides test result caching, fingerprinting, and selective execution:
 * - Cache test results with fingerprints
 * - Skip tests that haven't changed
 * - Report progress incrementally
 * - Focus on failing tests
 *
 * HOW: Uses file fingerprints and result caching:
 * - Compute MD5 of test source files
 * - Store results in .test-cache directory
 * - Compare fingerprints on re-run
 * - Only execute changed or failed tests
 *
 * ARCHITECTURE BENEFITS:
 * - Faster iteration cycles when developing builders
 * - Clear progress tracking
 * - Reduced CI times
 * - Better developer experience
 *
 * @see Codex architectural recommendations for modular testing
 */
class TestProgressTracker {
    private var cacheDir: String;
    private var resultsFile: String;
    private var results: Map<String, TestResult>;

    /**
     * Test result structure
     */
    typedef TestResult = {
        var passed: Bool;
        var fingerprint: String;
        var lastRun: Float;
        var error: Null<String>;
    }

    public function new(?cacheDir: String) {
        this.cacheDir = cacheDir != null ? cacheDir : ".test-cache";
        this.resultsFile = Path.join([this.cacheDir, "test-results.json"]);
        this.results = new Map();

        // Ensure cache directory exists
        if (!FileSystem.exists(this.cacheDir)) {
            FileSystem.createDirectory(this.cacheDir);
        }

        // Load previous results if they exist
        loadResults();
    }

    /**
     * Check if a test needs to be run
     *
     * @param testName Name of the test
     * @param testPath Path to test source file
     * @return True if test should be executed
     */
    public function shouldRunTest(testName: String, testPath: String): Bool {
        if (!FileSystem.exists(testPath)) {
            return true; // New test, always run
        }

        var currentFingerprint = computeFingerprint(testPath);

        if (!results.exists(testName)) {
            return true; // Never run before
        }

        var lastResult = results.get(testName);

        // Run if:
        // 1. Fingerprint changed (test modified)
        // 2. Last run failed (retry failures)
        // 3. Force flag is set (environment variable)
        return lastResult.fingerprint != currentFingerprint ||
               !lastResult.passed ||
               Sys.getEnv("FORCE_TESTS") == "1";
    }

    /**
     * Record test result
     *
     * @param testName Name of the test
     * @param testPath Path to test source
     * @param passed Whether test passed
     * @param error Error message if failed
     */
    public function recordResult(testName: String, testPath: String, passed: Bool, ?error: String): Void {
        var fingerprint = computeFingerprint(testPath);

        results.set(testName, {
            passed: passed,
            fingerprint: fingerprint,
            lastRun: Sys.time(),
            error: error
        });

        // Save immediately for incremental progress
        saveResults();
    }

    /**
     * Get summary of test results
     *
     * @return Summary statistics
     */
    public function getSummary(): {total: Int, passed: Int, failed: Int, skipped: Int} {
        var total = 0;
        var passed = 0;
        var failed = 0;

        for (result in results) {
            total++;
            if (result.passed) {
                passed++;
            } else {
                failed++;
            }
        }

        return {
            total: total,
            passed: passed,
            failed: failed,
            skipped: 0 // Will be set by test runner
        };
    }

    /**
     * Get list of failed tests
     *
     * @return Array of test names that failed
     */
    public function getFailedTests(): Array<String> {
        var failed = [];
        for (name in results.keys()) {
            if (!results.get(name).passed) {
                failed.push(name);
            }
        }
        return failed;
    }

    /**
     * Clear cache for specific test or all tests
     *
     * @param testName Optional test name to clear, or null for all
     */
    public function clearCache(?testName: String): Void {
        if (testName != null) {
            results.remove(testName);
        } else {
            results.clear();
        }
        saveResults();
    }

    /**
     * Compute fingerprint for a test file
     *
     * @param testPath Path to test file
     * @return MD5 hash of file contents
     */
    private function computeFingerprint(testPath: String): String {
        if (!FileSystem.exists(testPath)) {
            return "";
        }

        var content = File.getContent(testPath);

        // Simple hash for now - could use proper MD5
        var hash = 0;
        for (i in 0...content.length) {
            hash = ((hash << 5) - hash) + content.charCodeAt(i);
            hash = hash & 0x7FFFFFFF; // Keep positive
        }

        return Std.string(hash);
    }

    /**
     * Load results from cache
     */
    private function loadResults(): Void {
        if (FileSystem.exists(resultsFile)) {
            try {
                var content = File.getContent(resultsFile);
                var data = Json.parse(content);

                // Convert JSON back to Map
                for (field in Reflect.fields(data)) {
                    results.set(field, Reflect.field(data, field));
                }
            } catch (e: Dynamic) {
                // Cache corrupted, start fresh
                results.clear();
            }
        }
    }

    /**
     * Save results to cache
     */
    private function saveResults(): Void {
        // Convert Map to object for JSON serialization
        var data = {};
        for (name in results.keys()) {
            Reflect.setField(data, name, results.get(name));
        }

        var json = Json.stringify(data, "\t");
        File.saveContent(resultsFile, json);
    }

    /**
     * Generate progress report
     *
     * @return Formatted progress string
     */
    public function getProgressReport(): String {
        var summary = getSummary();
        var report = [];

        report.push('Test Progress: ${summary.passed}/${summary.total} passed');

        if (summary.failed > 0) {
            report.push('\nFailed Tests:');
            for (name in getFailedTests()) {
                var result = results.get(name);
                report.push('  ❌ $name');
                if (result.error != null) {
                    report.push('     ${result.error}');
                }
            }
        }

        return report.join('\n');
    }
}

#end