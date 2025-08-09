package;

/**
 * Simple Example Compilation Test
 * 
 * Tests example compilation with direct execution and clear output
 */
class SimpleExampleTest {

    public static function main() {
        trace("🧪 Starting Example Compilation Tests...");
        
        var results = [];
        var totalTests = 0;
        var passedTests = 0;
        
        // Test each example
        var examples = [
            {name: "01-simple-modules", file: "compile-all.hxml"},
            {name: "02-mix-project", file: "build.hxml"}, 
            {name: "03-phoenix-app", file: "build.hxml"},
            {name: "04-ecto-migrations", file: "build.hxml"},
            {name: "05-heex-templates", file: "build.hxml"},
            {name: "06-user-management", file: "build.hxml"},
            {name: "07-protocols", file: "build.hxml"},
            {name: "08-behaviors", file: "build.hxml"},
            {name: "test-integration", file: "build.hxml"}
        ];
        
        for (example in examples) {
            totalTests++;
            trace("\n📋 Testing: " + example.name);
            
            var result = testExample(example.name, example.file);
            results.push(result);
            
            if (result.success) {
                trace("✅ " + example.name + " - PASSED");
                passedTests++;
            } else {
                trace("❌ " + example.name + " - FAILED");
                trace("   Error: " + result.error);
            }
        }
        
        // Summary
        trace("\n🎯 SUMMARY:");
        trace("   Total Tests: " + totalTests);
        trace("   Passed: " + passedTests);
        trace("   Failed: " + (totalTests - passedTests));
        
        if (passedTests == totalTests) {
            trace("🎉 ALL TESTS PASSED!");
            Sys.exit(0);
        } else {
            trace("💥 SOME TESTS FAILED");
            Sys.exit(1);
        }
    }
    
    static function testExample(exampleDir: String, hxmlFile: String): {success: Bool, error: String} {
        try {
            var cwd = Sys.getCwd();
            var examplePath = "examples/" + exampleDir;
            
            // Check if example directory exists
            if (!sys.FileSystem.exists(examplePath)) {
                return {success: false, error: "Example directory not found: " + examplePath};
            }
            
            // Check if hxml file exists
            var hxmlPath = examplePath + "/" + hxmlFile;
            if (!sys.FileSystem.exists(hxmlPath)) {
                return {success: false, error: "HXML file not found: " + hxmlPath};
            }
            
            // Change to example directory
            Sys.setCwd(examplePath);
            
            // Execute haxe compilation
            var exitCode = Sys.command("npx", ["haxe", hxmlFile]);
            
            // Restore working directory
            Sys.setCwd(cwd);
            
            if (exitCode == 0) {
                return {success: true, error: ""};
            } else {
                return {success: false, error: "Compilation failed with exit code: " + exitCode};
            }
            
        } catch (e: Dynamic) {
            return {success: false, error: "Exception: " + Std.string(e)};
        }
    }
}