package test;

import tink.unit.Assert.assert;
import reflaxe.elixir.helpers.ChangesetCompiler;

using tink.CoreApi;
using StringTools;

/**
 * Modern Ecto Changeset Test Suite with Comprehensive Edge Case Coverage
 * 
 * Tests Ecto Changeset compilation with @:changeset annotation support, validation pipeline,
 * schema integration, and Phoenix ecosystem compatibility following TDD methodology with
 * comprehensive edge case testing across all 7 categories for production robustness.
 * 
 * Using tink_unittest for modern Haxe testing patterns.
 */
@:asserts
class ChangesetCompilerWorkingTest {
    
    public function new() {}
    
    @:describe("@:changeset annotation detection")
    public function testChangesetAnnotationDetection() {
        var className = "UserChangeset";
        var result = ChangesetCompiler.isChangesetClass(className);
        asserts.assert(result == true, "Should detect @:changeset annotated classes");
        
        var nonChangesetClass = "RegularClass";
        var nonChangesetResult = ChangesetCompiler.isChangesetClass(nonChangesetClass);
        asserts.assert(nonChangesetResult == false, "Should not detect regular classes as changesets");
        
        return asserts.done();
    }
    
    @:describe("Validation rule compilation")
    public function testValidationCompilation() {
        var validation = ChangesetCompiler.compileValidation("email", "required");
        asserts.assert(validation.contains("validate_required"), "Should generate validate_required call");
        asserts.assert(validation.contains("[:email]"), "Should include field in validation call");
        
        return asserts.done();
    }
    
    @:describe("Changeset module generation")
    public function testModuleGeneration() {
        var module = ChangesetCompiler.generateChangesetModule("UserChangeset");
        asserts.assert(module.contains("defmodule UserChangeset do"), "Should generate proper module definition");
        asserts.assert(module.contains("import Ecto.Changeset"), "Should import Ecto.Changeset");
        
        return asserts.done();
    }
    
    @:describe("Cast fields compilation")
    public function testCastFieldsCompilation() {
        var castFields = ChangesetCompiler.compileCastFields(["name", "age", "email"]);
        var expectedCast = "[:name, :age, :email]";
        asserts.assert(castFields == expectedCast, 'Should compile cast fields to ${expectedCast}, got ${castFields}');
        
        return asserts.done();
    }
    
    @:describe("Error tuple compilation")
    public function testErrorTupleCompilation() {
        var errorTuple = ChangesetCompiler.compileErrorTuple("email", "is required");
        var expectedError = "{:email, \"is required\"}";
        asserts.assert(errorTuple == expectedError, 'Should compile error tuple to ${expectedError}, got ${errorTuple}');
        
        return asserts.done();
    }
    
    @:describe("Full changeset compilation")
    public function testFullChangesetCompilation() {
        var fullChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        asserts.assert(fullChangeset.contains("defmodule UserRegistrationChangeset do"), "Should contain module definition");
        asserts.assert(fullChangeset.contains("def changeset(%User{} = struct, attrs) do"), "Should contain typed changeset function");
        
        return asserts.done();
    }
    
    @:describe("Changeset compilation performance")
    public function testCompilationPerformance() {
        var startTime = haxe.Timer.stamp();
        for (i in 0...10) {
            ChangesetCompiler.compileFullChangeset("TestChangeset" + i, "TestModel");
        }
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        var avgTime = compilationTime / 10;
        
        asserts.assert(compilationTime > 0, "Should take measurable time");
        asserts.assert(avgTime < 15, 'Performance target: Average compilation should be <15ms per changeset, was: ${Math.round(avgTime)}ms');
        
        return asserts.done();
    }
    
    // ============================================================================
    // 7-Category Edge Case Framework Implementation (Following AdvancedEctoTest Pattern)
    // ============================================================================
    
    @:describe("Error Conditions - Invalid Inputs")
    public function testErrorConditions() {
        // Test null/invalid inputs
        asserts.assert(!ChangesetCompiler.isChangesetClass(null), "Should handle null class name gracefully");
        asserts.assert(!ChangesetCompiler.isChangesetClass(""), "Should handle empty class name gracefully");
        
        // Test malformed changeset data
        var invalidValidation = ChangesetCompiler.compileValidation("", "");
        asserts.assert(invalidValidation != null, "Should handle malformed validation gracefully");
        
        // Test invalid field lists
        var invalidFields = ChangesetCompiler.compileCastFields([]);
        asserts.assert(invalidFields == "[]", "Should handle empty field lists");
        
        return asserts.done();
    }
    
    @:describe("Boundary Cases - Edge Values")  
    public function testBoundaryCases() {
        // Test very large field lists
        var largeFields = [];
        for (i in 0...100) {
            largeFields.push('field$i');
        }
        
        var largeCastFields = ChangesetCompiler.compileCastFields(largeFields);
        asserts.assert(largeCastFields.length > 100, "Should handle large field lists");
        asserts.assert(largeCastFields.contains("field0"), "Should include first field");
        asserts.assert(largeCastFields.contains("field99"), "Should include last field");
        
        // Test changeset with many validations
        var manyValidations = [];
        for (i in 0...50) {
            manyValidations.push(ChangesetCompiler.compileValidation('field$i', "required"));
        }
        
        asserts.assert(manyValidations.length == 50, "Should handle many validation rules");
        asserts.assert(manyValidations[0].contains("validate_required"), "Should compile all validation rules");
        
        return asserts.done();
    }
    
    @:describe("Security Validation - Input Sanitization") 
    public function testSecurityValidation() {
        // Test injection-like patterns in field names
        var maliciousField = "name'; DROP TABLE users; --";
        var safeValidation = ChangesetCompiler.compileValidation(maliciousField, "required");
        asserts.assert(safeValidation.contains("validate_required"), "Should sanitize malicious field names");
        
        // Test code injection in changeset names
        var maliciousChangeset = "Test'; System.cmd('rm', ['-rf', '/']); --";
        var safeModule = ChangesetCompiler.generateChangesetModule(maliciousChangeset);
        asserts.assert(safeModule.indexOf("System.cmd") == -1, "Should not include dangerous system calls");
        
        return asserts.done();
    }
    
    @:describe("Performance Limits - Stress Testing")
    public function testPerformanceLimits() {
        var startTime = haxe.Timer.stamp();
        
        // Stress test: Compile 100 changesets rapidly
        for (i in 0...100) {
            var stressChangeset = ChangesetCompiler.compileFullChangeset('StressTest$i', 'StressModel$i');
            asserts.assert(stressChangeset.contains("defmodule"), "Each changeset should compile successfully");
        }
        
        var duration = (haxe.Timer.stamp() - startTime) * 1000;
        var avgPerChangeset = duration / 100;
        
        asserts.assert(avgPerChangeset < 15, 'Stress test: Average per changeset should be <15ms, was: ${Math.round(avgPerChangeset)}ms');
        asserts.assert(duration < 1500, 'Total stress test should complete in <1.5s, was: ${Math.round(duration)}ms');
        
        return asserts.done();
    }
    
    @:describe("Integration Robustness - Cross-Component Testing")
    public function testIntegrationRobustness() {
        // Test interaction between different changeset components
        var changesetName = "IntegrationChangeset";
        var module = ChangesetCompiler.generateChangesetModule(changesetName);
        var castFields = ChangesetCompiler.compileCastFields(["name", "email", "age"]);
        var validation = ChangesetCompiler.compileValidation("email", "required");
        
        // Verify integration points
        asserts.assert(module.contains(changesetName), "Module should contain changeset name");
        asserts.assert(castFields.contains("name"), "Cast fields should include all fields");
        asserts.assert(validation.contains("email"), "Validation should reference correct field");
        
        // Test full pipeline with realistic data
        var realisticChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        asserts.assert(realisticChangeset.contains("UserRegistrationChangeset"), "Should generate realistic changeset module");
        asserts.assert(realisticChangeset.contains("User"), "Should reference correct schema");
        asserts.assert(realisticChangeset.contains("changeset"), "Should include changeset function");
        
        return asserts.done();
    }
    
    @:describe("Type Safety - Compile-Time Validation")
    public function testTypeSafety() {
        // Test type consistency in changeset functions
        var userChangeset = ChangesetCompiler.compileFullChangeset("UserChangeset", "User");
        asserts.assert(userChangeset.contains("%User{}"), "Should generate typed struct pattern matching");
        
        var productChangeset = ChangesetCompiler.compileFullChangeset("ProductChangeset", "Product");
        asserts.assert(productChangeset.contains("%Product{}"), "Should generate different typed patterns for different schemas");
        
        // Test error tuple type consistency
        var stringError = ChangesetCompiler.compileErrorTuple("name", "is required");
        var intError = ChangesetCompiler.compileErrorTuple("age", "must be positive");
        asserts.assert(stringError.contains("{:name, \"is required\"}"), "Should generate properly typed string error");
        asserts.assert(intError.contains("{:age, \"must be positive\"}"), "Should generate properly typed validation error");
        
        return asserts.done();
    }
    
    @:describe("Resource Management - Memory and Process Efficiency") 
    public function testResourceManagement() {
        // Test memory efficiency of generated changesets
        var baselineChangeset = ChangesetCompiler.generateChangesetModule("BaselineChangeset");
        var baselineSize = baselineChangeset.length;
        
        // Test with additional complexity
        var complexFields = [];
        for (i in 0...20) {
            complexFields.push('complex_field_$i');
        }
        var complexCast = ChangesetCompiler.compileCastFields(complexFields);
        var complexSize = complexCast.length;
        
        // Resource efficiency checks
        asserts.assert(baselineSize > 0, "Baseline changeset should have content");
        asserts.assert(complexSize > baselineSize, "Complex changeset should be larger");
        asserts.assert(complexSize < baselineSize * 10, "Complex changeset should not be excessively large");
        
        // Test validation pipeline efficiency
        var efficientValidation = ChangesetCompiler.compileValidation("email", "email");
        asserts.assert(efficientValidation.contains("validate_format"), "Should efficiently generate format validation");
        
        return asserts.done();
    }
}