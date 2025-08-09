package;

import tink.testrunner.Runner;
import tink.unit.TestBatch;
import tink.unit.Assert.*;
using tink.CoreApi;

/**
 * Comprehensive Example Compilation Test Suite
 * 
 * Tests all 7 examples for successful compilation and validation.
 * Follows Testing Trophy methodology with integration-focused approach.
 */
@:asserts
class ExampleCompilationTest {

    public function new() {}

    @:describe("01-simple-modules - Basic Module Compilation")
    public function testSimpleModules() {
        // Test the compile-all approach used in examples
        var allResult = compileExample("01-simple-modules", "compile-all.hxml");
        asserts.assert(allResult.success, "All simple modules should compile together: " + allResult.error);
        
        return asserts.done();
    }

    @:describe("02-mix-project - Mix Integration Compilation")
    public function testMixProject() {
        var result = compileExample("02-mix-project", "build.hxml");
        asserts.assert(result.success, "Mix project example should compile successfully");
        
        // Verify that generated Elixir files exist
        var generatedFiles = verifyGeneratedFiles("02-mix-project", [
            "lib/utils/string_utils.ex",
            "lib/utils/math_helper.ex", 
            "lib/utils/validation_helper.ex",
            "lib/services/user_service.ex"
        ]);
        asserts.assert(generatedFiles.success, "Generated Elixir files should exist");
        
        return asserts.done();
    }

    @:describe("03-phoenix-app - Phoenix LiveView Compilation")
    public function testPhoenixApp() {
        var result = compileExample("03-phoenix-app", "build.hxml");
        asserts.assert(result.success, "Phoenix application should compile successfully");
        
        // Verify LiveView modules are generated
        var liveviewFiles = verifyGeneratedFiles("03-phoenix-app", [
            "lib/phoenix/application.ex"
        ]);
        asserts.assert(liveviewFiles.success, "Phoenix modules should be generated");
        
        return asserts.done();
    }

    @:describe("04-ecto-migrations - Migration DSL Compilation")
    public function testEctoMigrations() {
        var result = compileExample("04-ecto-migrations", "build.hxml");
        asserts.assert(result.success, "Ecto migrations should compile successfully");
        
        // Verify migration modules are generated
        var migrationFiles = verifyGeneratedFiles("04-ecto-migrations", [
            "lib/migrations/create_users.ex",
            "lib/migrations/create_posts.ex"
        ]);
        asserts.assert(migrationFiles.success, "Migration modules should be generated");
        
        return asserts.done();
    }

    @:describe("05-heex-templates - Template Compilation")
    public function testHeexTemplates() {
        var result = compileExample("05-heex-templates", "build.hxml");
        asserts.assert(result.success, "HEEx templates should compile successfully");
        
        // Verify template modules are generated
        var templateFiles = verifyGeneratedFiles("05-heex-templates", [
            "lib/templates/user_profile.ex",
            "lib/templates/form_components.ex"
        ]);
        asserts.assert(templateFiles.success, "Template modules should be generated");
        
        return asserts.done();
    }

    @:describe("06-user-management - Advanced Integration")
    public function testUserManagement() {
        var result = compileExample("06-user-management", "build.hxml");
        asserts.assert(result.success, "User management system should compile successfully");
        
        // Verify all component types are generated
        var componentFiles = verifyGeneratedFiles("06-user-management", [
            "lib/contexts/users.ex",
            "lib/live/user_live.ex", 
            "lib/services/user_gen_server.ex"
        ]);
        asserts.assert(componentFiles.success, "All user management components should be generated");
        
        return asserts.done();
    }

    @:describe("test-integration - Build Pipeline Testing")
    public function testIntegration() {
        var result = compileExample("test-integration", "build.hxml");
        asserts.assert(result.success, "Integration test module should compile successfully");
        
        return asserts.done();
    }

    @:describe("Performance: All Examples Under 5 Seconds")
    public function testCompilationPerformance() {
        var startTime = Sys.time();
        
        // Compile all examples sequentially
        compileExample("01-simple-modules", "compile-all.hxml");
        compileExample("02-mix-project", "build.hxml");
        compileExample("03-phoenix-app", "build.hxml");
        compileExample("04-ecto-migrations", "build.hxml");
        compileExample("05-heex-templates", "build.hxml");
        compileExample("06-user-management", "build.hxml");
        compileExample("test-integration", "build.hxml");
        
        var totalTime = Sys.time() - startTime;
        
        asserts.assert(totalTime < 5.0, "All examples should compile in under 5 seconds, took: " + totalTime + "s");
        
        return asserts.done();
    }

    @:describe("Regression Prevention: No Compilation Warnings")
    public function testNoWarnings() {
        // Test that examples compile without warnings
        var examples = [
            {dir: "01-simple-modules", file: "compile-all.hxml"},
            {dir: "02-mix-project", file: "build.hxml"},
            {dir: "03-phoenix-app", file: "build.hxml"},
            {dir: "04-ecto-migrations", file: "build.hxml"},
            {dir: "05-heex-templates", file: "build.hxml"},
            {dir: "06-user-management", file: "build.hxml"},
            {dir: "test-integration", file: "build.hxml"}
        ];
        
        for (example in examples) {
            var result = compileExample(example.dir, example.file);
            asserts.assert(result.warnings == 0, example.dir + " should compile without warnings, got: " + result.warnings);
        }
        
        return asserts.done();
    }

    // Helper function to compile an example and return result
    private function compileExample(exampleDir: String, hxmlFile: String): CompilationResult {
        try {
            var cwd = Sys.getCwd();
            Sys.setCwd("examples/" + exampleDir);
            
            // Execute haxe compilation
            var process = new sys.io.Process("npx", ["haxe", hxmlFile]);
            var exitCode = process.exitCode();
            var stderr = process.stderr.readAll().toString();
            var stdout = process.stdout.readAll().toString();
            
            process.close();
            Sys.setCwd(cwd);
            
            // Count warnings in output
            var warningCount = countWarnings(stderr + stdout);
            
            return {
                success: exitCode == 0,
                exitCode: exitCode,
                output: stdout,
                error: stderr,
                warnings: warningCount
            };
            
        } catch (e: Dynamic) {
            return {
                success: false,
                exitCode: -1,
                output: "",
                error: "Exception: " + e,
                warnings: 0
            };
        }
    }

    // Helper function to verify generated files exist
    private function verifyGeneratedFiles(exampleDir: String, expectedFiles: Array<String>): FileVerificationResult {
        var missingFiles = [];
        
        for (filePath in expectedFiles) {
            var fullPath = "examples/" + exampleDir + "/" + filePath;
            if (!sys.FileSystem.exists(fullPath)) {
                missingFiles.push(filePath);
            }
        }
        
        return {
            success: missingFiles.length == 0,
            missingFiles: missingFiles,
            checkedFiles: expectedFiles.length,
            foundFiles: expectedFiles.length - missingFiles.length
        };
    }

    // Helper function to count warnings in compilation output
    private function countWarnings(output: String): Int {
        var warningCount = 0;
        var lines = output.split("\n");
        
        for (line in lines) {
            if (line.toLowerCase().indexOf("warning") >= 0) {
                warningCount++;
            }
        }
        
        return warningCount;
    }

    public static function main() {
        trace("🧪 Starting Example Compilation Tests with tink_unittest...");
        Runner.run(TestBatch.make([
            new ExampleCompilationTest(),
        ])).handle(function(result) {
            trace("🎯 Example Test Results: " + result);
            Runner.exit(result);
        });
    }
}

typedef CompilationResult = {
    success: Bool,
    exitCode: Int,
    output: String,
    error: String,
    warnings: Int
}

typedef FileVerificationResult = {
    success: Bool,
    missingFiles: Array<String>,
    checkedFiles: Int,
    foundFiles: Int
}