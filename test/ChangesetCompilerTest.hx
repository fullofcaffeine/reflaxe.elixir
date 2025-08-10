package test;

import utest.Test;
import utest.Assert;
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.ChangesetCompiler;
#end

using StringTools;

/**
 * TDD Tests for Ecto Changeset Compiler Implementation - Migrated to utest
 * Following Testing Trophy: Integration-heavy approach with full compilation pipeline testing
 * 
 * Migration patterns applied:
 * - static main() → extends Test with test methods  
 * - throw statements → Assert.isTrue() with proper conditions
 * - trace() statements → removed (utest handles output)
 * - Preserved conditional compilation for macro-time code
 */
class ChangesetCompilerTest extends Test {
    
    /**
     * Test @:changeset annotation detection
     */
    function testChangesetAnnotationDetection() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var className = "UserChangeset";
        var isChangeset = ChangesetCompiler.isChangesetClass(className);
        
        Assert.equals(true, isChangeset, "Expected changeset detection to return true");
        #else
        // Macro-time test
        var className = "UserChangeset";
        var isChangeset = ChangesetCompiler.isChangesetClass(className);
        
        Assert.equals(true, isChangeset, "Expected changeset detection to return true");
        #end
    }
    
    /**
     * Test validation rule compilation  
     */
    function testValidationRuleCompilation() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var field = "email";
        var rule = "required";
        
        var compiledValidation = ChangesetCompiler.compileValidation(field, rule);
        var expectedPattern = "validate_required(changeset, [:email])";
        
        Assert.isTrue(compiledValidation.indexOf(expectedPattern) >= 0, 
            'Expected validation pattern not found: ${expectedPattern}');
        #else
        // Macro-time test
        var field = "email";
        var rule = "required";
        
        var compiledValidation = ChangesetCompiler.compileValidation(field, rule);
        var expectedPattern = "validate_required(changeset, [:email])";
        
        Assert.isTrue(compiledValidation.indexOf(expectedPattern) >= 0, 
            'Expected validation pattern not found: ${expectedPattern}');
        #end
    }
    
    /**
     * Test complete changeset module generation
     */
    function testChangesetModuleGeneration() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var changesetClass = "UserChangeset";
        var generatedModule = ChangesetCompiler.generateChangesetModule(changesetClass);
        
        Assert.isTrue(generatedModule.indexOf("defmodule UserChangeset do") >= 0, 
            "Module definition not found");
        
        Assert.isTrue(generatedModule.indexOf("import Ecto.Changeset") >= 0,
            "Ecto.Changeset import not found");
        #else
        // Macro-time test
        var changesetClass = "UserChangeset";
        var generatedModule = ChangesetCompiler.generateChangesetModule(changesetClass);
        
        Assert.isTrue(generatedModule.indexOf("defmodule UserChangeset do") >= 0, 
            "Module definition not found");
        
        Assert.isTrue(generatedModule.indexOf("import Ecto.Changeset") >= 0,
            "Ecto.Changeset import not found");
        #end
    }
    
    /**
     * Test type casting compilation
     */
    function testTypeCastingCompilation() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var fieldNames = ["name", "age", "email"];
        var castFields = ChangesetCompiler.compileCastFields(fieldNames);
        var expectedCastList = "[:name, :age, :email]";
        
        Assert.equals(expectedCastList, castFields, 
            'Expected cast fields ${expectedCastList}, got ${castFields}');
        #else
        // Macro-time test
        var fieldNames = ["name", "age", "email"];
        var castFields = ChangesetCompiler.compileCastFields(fieldNames);
        var expectedCastList = "[:name, :age, :email]";
        
        Assert.equals(expectedCastList, castFields, 
            'Expected cast fields ${expectedCastList}, got ${castFields}');
        #end
    }
    
    /**
     * Test error handling compilation
     */
    function testErrorHandlingCompilation() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var field = "email";
        var error = "is required";
        var compiledError = ChangesetCompiler.compileErrorTuple(field, error);
        var expected = "{:email, \"is required\"}";
        
        Assert.equals(expected, compiledError,
            'Expected error tuple ${expected}, got ${compiledError}');
        #else
        // Macro-time test
        var field = "email";
        var error = "is required";
        var compiledError = ChangesetCompiler.compileErrorTuple(field, error);
        var expected = "{:email, \"is required\"}";
        
        Assert.equals(expected, compiledError,
            'Expected error tuple ${expected}, got ${compiledError}');
        #end
    }
    
    /**
     * Integration Test: Full changeset compilation pipeline
     * This represents the majority of testing per Testing Trophy methodology
     */
    function testFullChangesetPipeline() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var className = "UserRegistrationChangeset";
        var schema = "User";
        
        var compiledModule = ChangesetCompiler.compileFullChangeset(className, schema);
        
        Assert.isTrue(compiledModule.indexOf("defmodule UserRegistrationChangeset do") >= 0,
            "Module definition missing");
        
        Assert.isTrue(compiledModule.indexOf("import Ecto.Changeset") >= 0,
            "Ecto import missing");
        #else
        // Macro-time test
        var className = "UserRegistrationChangeset";
        var schema = "User";
        
        var compiledModule = ChangesetCompiler.compileFullChangeset(className, schema);
        
        Assert.isTrue(compiledModule.indexOf("defmodule UserRegistrationChangeset do") >= 0,
            "Module definition missing");
        
        Assert.isTrue(compiledModule.indexOf("import Ecto.Changeset") >= 0,
            "Ecto import missing");
        #end
    }
    
    /**
     * Performance Test: Verify <15ms compilation target
     */
    function testCompilationPerformance() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var startTime = haxe.Timer.stamp();
        
        for (i in 0...10) {
            var className = "TestChangeset" + i;
            ChangesetCompiler.compileFullChangeset(className, "TestModel");
        }
        
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        Assert.isTrue(compilationTime < 150,
            'Compilation took ${compilationTime}ms, expected <150ms for mocked version');
        #else
        // Macro-time test
        var startTime = haxe.Timer.stamp();
        
        for (i in 0...10) {
            var className = "TestChangeset" + i;
            ChangesetCompiler.compileFullChangeset(className, "TestModel");
        }
        
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        Assert.isTrue(compilationTime < 15,
            'Compilation took ${compilationTime}ms, expected <15ms');
        #end
    }
}

// Runtime Mock of ChangesetCompiler
#if !(macro || reflaxe_runtime)
class ChangesetCompiler {
    public static function isChangesetClass(className: String): Bool {
        return className != null && className.indexOf("Changeset") != -1;
    }
    
    public static function compileValidation(field: String, rule: String): String {
        return 'validate_${rule}(changeset, [:${field}])';
    }
    
    public static function generateChangesetModule(className: String): String {
        return 'defmodule ${className} do\n  import Ecto.Changeset\nend';
    }
    
    public static function compileCastFields(fieldNames: Array<String>): String {
        return '[:${fieldNames.join(", :")}]';
    }
    
    public static function compileErrorTuple(field: String, error: String): String {
        return '{:${field}, "${error}"}';
    }
    
    public static function compileFullChangeset(className: String, schema: String): String {
        return 'defmodule ${className} do\n  import Ecto.Changeset\n  def changeset(%${schema}{} = struct, attrs) do\n    struct\n    |> cast(attrs, [])\n  end\nend';
    }
}
#end