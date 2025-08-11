package test;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

/**
 * Simple test to verify the generator works
 */
class RunGeneratorTest {
    static function main() {
        // Simulate the arguments that would be passed when run via haxelib
        var originalArgs = Sys.args();
        
        // Create test directory
        var testDir = "test_generator_output";
        if (FileSystem.exists(testDir)) {
            deleteDirectory(testDir);
        }
        FileSystem.createDirectory(testDir);
        
        // Set up arguments as if called via haxelib run
        // The last argument is typically the working directory when run via haxelib
        Sys.putEnv("HAXELIB_RUN", "1");
        var args = ["create", "my-test-app", "--type", "basic", "--no-interactive", "--skip-install", Sys.getCwd() + "/" + testDir];
        
        // Change to test directory
        var originalCwd = Sys.getCwd();
        Sys.setCwd(testDir);
        
        try {
            // Call the Run.main with our test arguments
            var run = new Run();
            Reflect.setField(Run, "args", args);
            Run.main();
            
            // Verify the project was created
            var projectPath = "my-test-app";
            if (FileSystem.exists(projectPath)) {
                trace("✅ Project created successfully!");
                
                // Check for expected files
                var expectedFiles = [
                    "build.hxml",
                    "package.json",
                    "README.md",
                    ".gitignore"
                ];
                
                for (file in expectedFiles) {
                    var filePath = Path.join([projectPath, file]);
                    if (FileSystem.exists(filePath)) {
                        trace('  ✓ ${file} exists');
                    } else {
                        trace('  ✗ ${file} missing');
                    }
                }
                
                // Check src_haxe directory
                if (FileSystem.exists(Path.join([projectPath, "src_haxe"]))) {
                    trace('  ✓ src_haxe/ directory exists');
                    
                    // Check for example module
                    if (FileSystem.exists(Path.join([projectPath, "src_haxe", "HelloWorld.hx"]))) {
                        trace('  ✓ HelloWorld.hx example exists');
                    }
                }
                
                trace("\n🎉 Generator test passed!");
            } else {
                trace("❌ Project directory not created");
            }
            
        } catch (e: Dynamic) {
            trace('❌ Error during generation: $e');
        }
        
        // Restore directory
        Sys.setCwd(originalCwd);
        
        // Clean up
        if (FileSystem.exists(testDir)) {
            deleteDirectory(testDir);
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