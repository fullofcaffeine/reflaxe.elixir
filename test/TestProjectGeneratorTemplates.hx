package test;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import reflaxe.elixir.generator.ProjectGenerator;

/**
 * Test that ProjectGenerator correctly processes templates
 */
class TestProjectGeneratorTemplates {
    static var testsPassed = 0;
    static var testsFailed = 0;
    
    static function main() {
        trace("Testing ProjectGenerator Template System...\n");
        
        // Create test directory
        var testDir = "test_generator_templates";
        if (FileSystem.exists(testDir)) {
            deleteDirectory(testDir);
        }
        FileSystem.createDirectory(testDir);
        
        try {
            testBasicProject(testDir);
            testLLMDocumentationGeneration(testDir);
            testTemplateProcessing(testDir);
            
            trace("\n========================================");
            trace('Tests Passed: $testsPassed');
            trace('Tests Failed: $testsFailed');
            
            if (testsFailed == 0) {
                trace("✅ All template tests passed!");
            } else {
                trace('❌ $testsFailed tests failed');
                Sys.exit(1);
            }
        } catch (e: Dynamic) {
            trace('❌ Fatal error: $e');
            // Clean up
            trace("\nCleaning up test files...");
            deleteDirectory(testDir);
            Sys.exit(1);
        }
        
        // Clean up on success
        trace("\nCleaning up test files...");
        deleteDirectory(testDir);
    }
    
    static function testBasicProject(testDir: String): Void {
        trace("\n=== Testing Basic Project Generation ===");
        
        var generator = new ProjectGenerator();
        var options = {
            name: "test-basic",
            type: "basic",
            skipInstall: true,
            verbose: false,
            vscode: false,
            workingDir: testDir
        };
        
        generator.generate(options);
        
        var projectPath = Path.join([testDir, "test-basic"]);
        
        // Check critical files exist
        assert(FileSystem.exists(projectPath), "Project directory created");
        assert(FileSystem.exists(Path.join([projectPath, "build.hxml"])), "build.hxml created");
        assert(FileSystem.exists(Path.join([projectPath, "package.json"])), "package.json created");
        assert(FileSystem.exists(Path.join([projectPath, "README.md"])), "README.md created");
        assert(FileSystem.exists(Path.join([projectPath, "CLAUDE.md"])), "CLAUDE.md created");
    }
    
    static function testLLMDocumentationGeneration(testDir: String): Void {
        trace("\n=== Testing LLM Documentation Generation ===");
        
        var generator = new ProjectGenerator();
        var options = {
            name: "test-llm-docs",
            type: "basic",
            skipInstall: true,
            verbose: false,
            vscode: false,
            workingDir: testDir
        };
        
        generator.generate(options);
        
        var projectPath = Path.join([testDir, "test-llm-docs"]);
        var llmDocsPath = Path.join([projectPath, ".taskmaster", "docs", "llm"]);
        
        // Check LLM documentation structure
        assert(FileSystem.exists(llmDocsPath), ".taskmaster/docs/llm directory created");
        
        // Check foundation docs are copied
        assert(
            FileSystem.exists(Path.join([llmDocsPath, "HAXE_FUNDAMENTALS.md"])),
            "HAXE_FUNDAMENTALS.md copied"
        );
        assert(
            FileSystem.exists(Path.join([llmDocsPath, "REFLAXE_ELIXIR_BASICS.md"])),
            "REFLAXE_ELIXIR_BASICS.md copied"
        );
        assert(
            FileSystem.exists(Path.join([llmDocsPath, "QUICK_START_PATTERNS.md"])),
            "QUICK_START_PATTERNS.md copied"
        );
        
        // Check generated docs
        assert(
            FileSystem.exists(Path.join([llmDocsPath, "API_REFERENCE_SKELETON.md"])),
            "API_REFERENCE_SKELETON.md generated"
        );
        assert(
            FileSystem.exists(Path.join([llmDocsPath, "PROJECT_SPECIFICS.md"])),
            "PROJECT_SPECIFICS.md generated"
        );
        
        // Check patterns directory
        var patternsPath = Path.join([projectPath, ".taskmaster", "docs", "patterns"]);
        assert(FileSystem.exists(patternsPath), "patterns directory created");
        assert(
            FileSystem.exists(Path.join([patternsPath, "PATTERNS.md"])),
            "PATTERNS.md generated"
        );
    }
    
    static function testTemplateProcessing(testDir: String): Void {
        trace("\n=== Testing Template Processing ===");
        
        var generator = new ProjectGenerator();
        var options = {
            name: "test-template-vars",
            type: "phoenix",
            skipInstall: true,
            verbose: false,
            vscode: false,
            workingDir: testDir
        };
        
        generator.generate(options);
        
        var projectPath = Path.join([testDir, "test-template-vars"]);
        
        // Check CLAUDE.md has correct placeholders replaced
        var claudeContent = File.getContent(Path.join([projectPath, "CLAUDE.md"]));
        assert(claudeContent.indexOf("test-template-vars") > -1, "Project name replaced in CLAUDE.md");
        assert(claudeContent.indexOf("{{PROJECT_NAME}}") == -1, "No unreplaced placeholders in CLAUDE.md");
        
        // Check README.md processing
        var readmeContent = File.getContent(Path.join([projectPath, "README.md"]));
        assert(readmeContent.indexOf("test-template-vars") > -1, "Project name replaced in README.md");
        assert(readmeContent.indexOf("{{PROJECT_NAME}}") == -1, "No unreplaced placeholders in README.md");
        
        // Check Phoenix-specific content is included
        assert(claudeContent.indexOf("Phoenix Development") > -1, "Phoenix content in CLAUDE.md");
        assert(readmeContent.indexOf("Phoenix") > -1, "Phoenix content in README.md");
    }
    
    static function assert(condition: Bool, message: String): Void {
        if (condition) {
            trace('  ✅ $message');
            testsPassed++;
        } else {
            trace('  ❌ $message');
            testsFailed++;
        }
    }
    
    static function deleteDirectory(path: String): Void {
        if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
            for (item in FileSystem.readDirectory(path)) {
                var itemPath = Path.join([path, item]);
                if (FileSystem.isDirectory(itemPath)) {
                    deleteDirectory(itemPath);
                } else {
                    FileSystem.deleteFile(itemPath);
                }
            }
            FileSystem.deleteDirectory(path);
        }
    }
}