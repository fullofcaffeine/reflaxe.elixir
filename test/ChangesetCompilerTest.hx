package test;

#if (macro || reflaxe_runtime)

using StringTools;

/**
 * TDD Tests for Ecto Changeset Compiler Implementation
 * Following Testing Trophy: Integration-heavy approach with full compilation pipeline testing
 */
class ChangesetCompilerTest {
    
    /**
     * 🔴 RED Phase: Test @:changeset annotation detection
     */
    public static function testChangesetAnnotationDetection(): Void {
        var className = "UserChangeset";
        var isChangeset = reflaxe.elixir.helpers.ChangesetCompiler.isChangesetClass(className);
        
        // This should initially fail - ChangesetCompiler doesn't exist yet
        var expected = true;
        if (isChangeset != expected) {
            throw "FAIL: Expected changeset detection to return " + expected + ", got " + isChangeset;
        }
        
        trace("✅ PASS: Changeset annotation detection working");
    }
    
    /**
     * 🔴 RED Phase: Test validation rule compilation  
     */
    public static function testValidationRuleCompilation(): Void {
        // Simplified test for RED phase - just test basic compilation
        var field = "email";
        var rule = "required";
        
        // Generate Ecto validation call
        var compiledValidation = reflaxe.elixir.helpers.ChangesetCompiler.compileValidation(field, rule);
        
        // Expected output should contain proper Ecto.Changeset function call
        var expectedPattern = "validate_required(changeset, [:email])";
        
        if (compiledValidation.indexOf(expectedPattern) == -1) {
            throw "FAIL: Expected validation pattern not found: " + expectedPattern;
        }
        
        trace("✅ PASS: Validation rule compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test complete changeset module generation
     */
    public static function testChangesetModuleGeneration(): Void {
        var changesetClass = "UserChangeset";
        
        // Generate complete Elixir changeset module
        var generatedModule = reflaxe.elixir.helpers.ChangesetCompiler.generateChangesetModule(changesetClass);
        
        // Verify module structure
        if (generatedModule.indexOf("defmodule UserChangeset do") == -1) {
            throw "FAIL: Module definition not found";
        }
        
        if (generatedModule.indexOf("import Ecto.Changeset") == -1) {
            throw "FAIL: Ecto.Changeset import not found";
        }
        
        trace("✅ PASS: Changeset module generation working");
    }
    
    /**
     * 🔴 RED Phase: Test type casting compilation
     */
    public static function testTypeCastingCompilation(): Void {
        var fieldNames = ["name", "age", "email"];
        var castFields = reflaxe.elixir.helpers.ChangesetCompiler.compileCastFields(fieldNames);
        var expectedCastList = "[:name, :age, :email]";
        
        if (castFields != expectedCastList) {
            throw "FAIL: Expected cast fields " + expectedCastList + ", got " + castFields;
        }
        
        trace("✅ PASS: Type casting compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test error handling compilation
     */
    public static function testErrorHandlingCompilation(): Void {
        var field = "email";
        var error = "is required";
        var compiledError = reflaxe.elixir.helpers.ChangesetCompiler.compileErrorTuple(field, error);
        var expected = "{:email, \"is required\"}";
        
        if (compiledError != expected) {
            throw "FAIL: Expected error tuple " + expected + ", got " + compiledError;
        }
        
        trace("✅ PASS: Error handling compilation working");
    }
    
    /**
     * Integration Test: Full changeset compilation pipeline
     * This represents the majority of testing per Testing Trophy methodology
     */
    public static function testFullChangesetPipeline(): Void {
        var className = "UserRegistrationChangeset";
        var schema = "User";
        
        // Full compilation should produce working Elixir changeset module
        var compiledModule = reflaxe.elixir.helpers.ChangesetCompiler.compileFullChangeset(className, schema);
        
        // Verify key integration points
        if (compiledModule.indexOf("defmodule UserRegistrationChangeset do") == -1) {
            throw "FAIL: Module definition missing";
        }
        
        if (compiledModule.indexOf("import Ecto.Changeset") == -1) {
            throw "FAIL: Ecto import missing";
        }
        
        trace("✅ PASS: Full changeset pipeline integration working");
    }
    
    /**
     * Performance Test: Verify <15ms compilation target
     */
    public static function testCompilationPerformance(): Void {
        var startTime = haxe.Timer.stamp();
        
        // Simulate compiling 10 changeset classes
        for (i in 0...10) {
            var className = "TestChangeset" + i;
            reflaxe.elixir.helpers.ChangesetCompiler.compileFullChangeset(className, "TestModel");
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
        trace("🔴 Starting RED Phase: ChangesetCompiler TDD Tests");
        trace("These tests SHOULD FAIL initially - that's the point of TDD!");
        
        try {
            testChangesetAnnotationDetection();
            testValidationRuleCompilation();
            testChangesetModuleGeneration();
            testTypeCastingCompilation();
            testErrorHandlingCompilation();
            testFullChangesetPipeline();
            testCompilationPerformance();
            
            trace("🟢 All tests pass - Ready for GREEN phase implementation!");
        } catch (error: String) {
            trace("🔴 Expected failure in RED phase: " + error);
            trace("✅ TDD RED phase complete - Now implement ChangesetCompiler.hx");
        }
    }
}

#end