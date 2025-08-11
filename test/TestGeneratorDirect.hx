package test;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import reflaxe.elixir.generator.ProjectGenerator;

/**
 * Direct test of the ProjectGenerator
 */
class TestGeneratorDirect {
    static function main() {
        trace("Testing Reflaxe.Elixir Project Generator...\n");
        
        // Create test directory
        var testDir = "test_generator_output";
        if (FileSystem.exists(testDir)) {
            deleteDirectory(testDir);
        }
        FileSystem.createDirectory(testDir);
        
        // Create generator
        var generator = new ProjectGenerator();
        
        // Test basic project generation
        try {
            var options = {
                name: "test-basic-project",
                type: "basic",
                skipInstall: true,
                verbose: true,
                vscode: false,
                workingDir: testDir
            };
            
            trace("Creating basic project...");
            generator.generate(options);
            
            // Verify project structure
            var projectPath = Path.join([testDir, "test-basic-project"]);
            
            if (FileSystem.exists(projectPath)) {
                trace("✅ Project directory created");
                
                // Check files
                checkFile(projectPath, "build.hxml");
                checkFile(projectPath, "package.json");
                checkFile(projectPath, "README.md");
                checkFile(projectPath, ".gitignore");
                
                trace("\n✨ Basic project generation successful!\n");
            } else {
                trace("❌ Project directory not created");
            }
            
        } catch (e: Dynamic) {
            trace('❌ Error: $e');
        }
        
        // Test add-to-existing
        try {
            // Create fake Elixir project
            var existingPath = Path.join([testDir, "existing-elixir"]);
            FileSystem.createDirectory(existingPath);
            File.saveContent(Path.join([existingPath, "mix.exs"]), 
                'defmodule TestProject.MixProject do\n  use Mix.Project\nend');
            
            var options = {
                name: "existing-elixir",
                type: "add-to-existing",
                skipInstall: true,
                verbose: true,
                vscode: false,
                workingDir: existingPath
            };
            
            trace("Adding to existing Elixir project...");
            generator.generate(options);
            
            // Verify additions
            if (FileSystem.exists(Path.join([existingPath, "src_haxe"]))) {
                trace("✅ src_haxe directory added");
                checkFile(existingPath, "build.hxml");
                checkFile(existingPath, "package.json");
                checkFile(Path.join([existingPath, "src_haxe"]), "HelloWorld.hx");
                trace("\n✨ Add-to-existing successful!\n");
            } else {
                trace("❌ src_haxe directory not created");
            }
            
        } catch (e: Dynamic) {
            trace('❌ Error: $e');
        }
        
        // Clean up
        trace("Cleaning up test files...");
        deleteDirectory(testDir);
        trace("✅ Test complete!");
    }
    
    static function checkFile(dir: String, file: String): Void {
        var path = Path.join([dir, file]);
        if (FileSystem.exists(path)) {
            trace('  ✓ ${file}');
        } else {
            trace('  ✗ ${file} missing');
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