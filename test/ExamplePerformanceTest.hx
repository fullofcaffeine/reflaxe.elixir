package;

/**
 * Example Performance Benchmarking Test
 * 
 * Monitors compilation performance to ensure examples remain fast
 * and detect any performance regressions.
 */
class ExamplePerformanceTest {

    public static function main() {
        trace("⚡ Starting Example Performance Benchmarking...");
        
        var results = [];
        var totalStartTime = Sys.time();
        
        // Performance targets for full example compilation (includes dependencies)
        // Note: 15ms is for individual compilation steps, examples are full builds
        var TARGET_TIME_MS = 1000.0; // 1 second for full example compilation
        
        var examples = [
            {name: "01-simple-modules", file: "compile-all.hxml"},
            {name: "02-mix-project", file: "build.hxml"}, 
            {name: "03-phoenix-app", file: "build.hxml"},
            {name: "04-ecto-migrations", file: "build.hxml"},
            {name: "05-heex-templates", file: "build.hxml"},
            {name: "06-user-management", file: "build.hxml"},
            {name: "test-integration", file: "build.hxml"}
        ];
        
        var allPassed = true;
        var totalCompilations = 0;
        var totalCompilationTime = 0.0;
        
        for (example in examples) {
            totalCompilations++;
            trace("\n⏱️ Benchmarking: " + example.name);
            
            var result = benchmarkExample(example.name, example.file, TARGET_TIME_MS);
            results.push(result);
            totalCompilationTime += result.compilationTime;
            
            if (result.success) {
                var timeMs = result.compilationTime * 1000;
                trace("✅ " + example.name + " - " + Math.round(timeMs * 100)/100 + "ms");
                
                if (timeMs > TARGET_TIME_MS) {
                    trace("⚠️ WARNING: " + example.name + " exceeded target time (" + TARGET_TIME_MS + "ms)");
                }
            } else {
                trace("❌ " + example.name + " - FAILED: " + result.error);
                allPassed = false;
            }
        }
        
        var totalTime = Sys.time() - totalStartTime;
        var avgCompileTime = (totalCompilationTime / totalCompilations) * 1000;
        
        // Performance Summary
        trace("\n⚡ PERFORMANCE SUMMARY:");
        trace("   Total Examples: " + totalCompilations);
        trace("   Total Time: " + Math.round(totalTime * 100)/100 + "s");
        trace("   Average Compilation: " + Math.round(avgCompileTime * 100)/100 + "ms");
        trace("   Target: <" + TARGET_TIME_MS + "ms per compilation");
        trace("   Status: " + (avgCompileTime < TARGET_TIME_MS ? "✅ MEETS TARGET" : "⚠️ EXCEEDS TARGET"));
        
        // Individual Results
        trace("\n📊 INDIVIDUAL RESULTS:");
        for (result in results) {
            if (result.success) {
                var timeMs = Math.round(result.compilationTime * 1000 * 100)/100;
                var status = timeMs < TARGET_TIME_MS ? "✅" : "⚠️";
                trace("   " + status + " " + result.name + ": " + timeMs + "ms");
            }
        }
        
        if (allPassed && avgCompileTime < TARGET_TIME_MS) {
            trace("\n🚀 ALL PERFORMANCE TARGETS MET!");
            Sys.exit(0);
        } else {
            trace("\n⚠️ PERFORMANCE ISSUES DETECTED");
            Sys.exit(1);
        }
    }
    
    static function benchmarkExample(exampleDir: String, hxmlFile: String, targetMs: Float): PerformanceResult {
        try {
            var cwd = Sys.getCwd();
            var examplePath = "examples/" + exampleDir;
            
            if (!sys.FileSystem.exists(examplePath + "/" + hxmlFile)) {
                return {
                    name: exampleDir,
                    success: false,
                    compilationTime: 0.0,
                    error: "Build file not found: " + hxmlFile
                };
            }
            
            Sys.setCwd(examplePath);
            
            // Warm-up compilation (excluded from timing)
            Sys.command("npx", ["haxe", hxmlFile]);
            
            // Timed compilation
            var startTime = Sys.time();
            var exitCode = Sys.command("npx", ["haxe", hxmlFile]);
            var compilationTime = Sys.time() - startTime;
            
            Sys.setCwd(cwd);
            
            return {
                name: exampleDir,
                success: exitCode == 0,
                compilationTime: compilationTime,
                error: exitCode == 0 ? "" : "Exit code: " + exitCode
            };
            
        } catch (e: Dynamic) {
            return {
                name: exampleDir,
                success: false,
                compilationTime: 0.0,
                error: "Exception: " + Std.string(e)
            };
        }
    }
}

typedef PerformanceResult = {
    name: String,
    success: Bool,
    compilationTime: Float,
    error: String
}