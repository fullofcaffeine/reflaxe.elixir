package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.MigrationDSL;

/**
 * TDD Tests for Ecto Migration DSL Implementation
 * Following Testing Trophy: Integration-heavy approach with full migration pipeline testing
 */
class MigrationDSLTest {
    
    /**
     * 🔴 RED Phase: Test @:migration annotation detection
     */
    public static function testMigrationAnnotationDetection(): Void {
        var className = "CreateUsersTable";
        var isMigration = MigrationDSL.isMigrationClass(className);
        
        // This should initially fail - MigrationDSL doesn't exist yet
        var expected = true;
        if (isMigration != expected) {
            throw "FAIL: Expected migration detection to return " + expected + ", got " + isMigration;
        }
        
        trace("✅ PASS: Migration annotation detection working");
    }
    
    /**
     * 🔴 RED Phase: Test table creation compilation
     */
    public static function testTableCreationCompilation(): Void {
        var tableName = "users";
        var columns = ["name:string", "email:string", "age:integer"];
        
        // Generate Ecto table creation
        var tableCreation = MigrationDSL.compileTableCreation(tableName, columns);
        
        // Expected output should contain proper Ecto.Migration table creation
        var expectedPatterns = [
            "create table(:users) do",
            "add :name, :string", 
            "add :email, :string",
            "add :age, :integer"
        ];
        
        for (pattern in expectedPatterns) {
            if (tableCreation.indexOf(pattern) == -1) {
                throw "FAIL: Expected table creation pattern not found: " + pattern;
            }
        }
        
        trace("✅ PASS: Table creation compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test migration module generation
     */
    public static function testMigrationModuleGeneration(): Void {
        var migrationClass = "CreateUsersTable";
        
        // Generate complete Elixir migration module
        var generatedModule = MigrationDSL.generateMigrationModule(migrationClass);
        
        // Verify module structure
        var requiredElements = [
            "defmodule CreateUsersTable do",
            "use Ecto.Migration",
            "def change do", 
            "def up do",
            "def down do",
            "end"
        ];
        
        for (element in requiredElements) {
            if (generatedModule.indexOf(element) == -1) {
                throw "FAIL: Required migration element not found: " + element;
            }
        }
        
        trace("✅ PASS: Migration module generation working");
    }
    
    /**
     * 🔴 RED Phase: Test index compilation
     */
    public static function testIndexCompilation(): Void {
        var tableName = "users";
        var indexFields = ["email"];
        var indexOptions = "unique: true";
        
        var indexCreation = MigrationDSL.compileIndexCreation(tableName, indexFields, indexOptions);
        var expectedIndex = "create unique_index(:users, [:email])";
        
        if (indexCreation.indexOf(expectedIndex) == -1) {
            throw "FAIL: Expected index creation not found: " + expectedIndex;
        }
        
        trace("✅ PASS: Index compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test rollback functionality
     */
    public static function testRollbackFunctionality(): Void {
        var tableName = "users";
        var rollbackCode = MigrationDSL.compileTableDrop(tableName);
        var expectedRollback = "drop table(:users)";
        
        if (rollbackCode != expectedRollback) {
            throw "FAIL: Expected rollback " + expectedRollback + ", got " + rollbackCode;
        }
        
        trace("✅ PASS: Rollback functionality working");
    }
    
    /**
     * 🔴 RED Phase: Test column modification compilation
     */
    public static function testColumnModificationCompilation(): Void {
        var tableName = "users";
        var columnName = "email";
        var modification = "null: false";
        
        var columnMod = MigrationDSL.compileColumnModification(tableName, columnName, modification);
        var expectedModification = "alter table(:users) do\n  modify :email, :string, null: false\nend";
        
        if (columnMod.indexOf("alter table(:users)") == -1) {
            throw "FAIL: Column modification should contain table alteration";
        }
        
        if (columnMod.indexOf("modify :email") == -1) {
            throw "FAIL: Column modification should modify email field";
        }
        
        trace("✅ PASS: Column modification compilation working");
    }
    
    /**
     * Integration Test: Full migration compilation pipeline
     * This represents the majority of testing per Testing Trophy methodology
     */
    public static function testFullMigrationPipeline(): Void {
        // Simulate a complete @:migration annotated class
        var migrationData = {
            className: "CreateUsersTable",
            timestamp: "20250808175000",
            tableName: "users",
            columns: ["name:string", "email:string"]
        };
        
        // Full compilation should produce working Elixir migration module
        var compiledModule = MigrationDSL.compileFullMigration(migrationData);
        
        // Verify integration points with Mix tasks and Ecto.Migrator
        var integrationChecks = [
            // Module definition with timestamp
            "defmodule Repo.Migrations.CreateUsersTable do",
            // Ecto.Migration use
            "use Ecto.Migration",
            // Change function with operations
            "def change do",
            "create table(:users)",
            "add :name, :string",
            "add :email, :string", 
            "create unique_index(:users, [:email])",
            // Proper end
            "end"
        ];
        
        for (check in integrationChecks) {
            if (compiledModule.indexOf(check) == -1) {
                throw "FAIL: Integration check failed - missing: " + check;
            }
        }
        
        trace("✅ PASS: Full migration pipeline integration working");
    }
    
    /**
     * Test Mix task integration and file generation
     */
    public static function testMixTaskIntegration(): Void {
        var migrationName = "CreateUsersTable";
        var timestamp = "20250808175000";
        
        // Test migration filename generation
        var filename = MigrationDSL.generateMigrationFilename(migrationName, timestamp);
        var expectedFilename = "20250808175000_create_users_table.exs";
        
        if (filename != expectedFilename) {
            throw "FAIL: Expected filename " + expectedFilename + ", got " + filename;
        }
        
        // Test migration file path generation
        var filepath = MigrationDSL.generateMigrationFilePath(migrationName, timestamp);
        var expectedPath = "priv/repo/migrations/20250808175000_create_users_table.exs";
        
        if (filepath != expectedPath) {
            throw "FAIL: Expected path " + expectedPath + ", got " + filepath;
        }
        
        trace("✅ PASS: Mix task integration working");
    }
    
    /**
     * Performance Test: Verify <15ms compilation target
     */
    public static function testCompilationPerformance(): Void {
        var startTime = haxe.Timer.stamp();
        
        // Simulate compiling 10 migration classes
        for (i in 0...10) {
            var migrationData = {
                className: "TestMigration" + i,
                timestamp: "2025080817500" + i,
                tableName: "test_table" + i,
                columns: ["name:string"]
            };
            MigrationDSL.compileFullMigration(migrationData);
        }
        
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000; // Convert to milliseconds
        
        // Performance target: <15ms compilation steps
        if (compilationTime > 15) {
            throw "FAIL: Compilation took " + compilationTime + "ms, expected <15ms";
        }
        
        trace("✅ PASS: Performance target met: " + compilationTime + "ms");
    }
    
    /**
     * Main test runner following TDD RED phase
     */
    public static function main(): Void {
        trace("🔴 Starting RED Phase: MigrationDSL TDD Tests");
        trace("These tests SHOULD FAIL initially - that's the point of TDD!");
        
        try {
            testMigrationAnnotationDetection();
            testTableCreationCompilation();
            testMigrationModuleGeneration();
            testIndexCompilation();
            testRollbackFunctionality();
            testColumnModificationCompilation();
            testFullMigrationPipeline();
            testMixTaskIntegration();
            testCompilationPerformance();
            
            trace("🟢 All tests pass - Ready for GREEN phase implementation!");
        } catch (error: String) {
            trace("🔴 Expected failure in RED phase: " + error);
            trace("✅ TDD RED phase complete - Now implement MigrationDSL.hx");
        }
    }
}

#end