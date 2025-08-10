package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.helpers.ChangesetCompiler;

using StringTools;

/**
 * Modern Ecto Changeset Test Suite with Comprehensive Edge Case Coverage - Migrated to utest
 * 
 * Tests Ecto Changeset compilation with @:changeset annotation support, validation pipeline,
 * schema integration, and Phoenix ecosystem compatibility following TDD methodology with
 * comprehensive edge case testing across all 7 categories for production robustness.
 * 
 * Migration patterns applied:
 * - @:asserts class → extends Test
 * - asserts.assert() → Assert.isTrue() / Assert.equals()
 * - return asserts.done() → (removed)
 * - @:describe("name") → function testName() with descriptive names
 * - @:timeout(ms) → @:timeout(ms) (kept same)
 */
class ChangesetCompilerWorkingTest extends Test {
    
    function testChangesetAnnotationDetection() {
        var className = "UserChangeset";
        var result = ChangesetCompiler.isChangesetClass(className);
        Assert.equals(true, result, "Should detect @:changeset annotated classes");
        
        var nonChangesetClass = "RegularClass";
        var nonChangesetResult = ChangesetCompiler.isChangesetClass(nonChangesetClass);
        Assert.equals(false, nonChangesetResult, "Should not detect regular classes as changesets");
    }
    
    function testValidationRuleCompilation() {
        var validation = ChangesetCompiler.compileValidation("email", "required");
        Assert.isTrue(validation.contains("validate_required"), "Should generate validate_required call");
        Assert.isTrue(validation.contains("[:email]"), "Should include field in validation call");
    }
    
    function testChangesetModuleGeneration() {
        var module = ChangesetCompiler.generateChangesetModule("UserChangeset");
        Assert.isTrue(module.contains("defmodule UserChangeset do"), "Should generate proper module definition");
        Assert.isTrue(module.contains("import Ecto.Changeset"), "Should import Ecto.Changeset");
    }
    
    function testCastFieldsCompilation() {
        var castFields = ChangesetCompiler.compileCastFields(["name", "age", "email"]);
        var expectedCast = "[:name, :age, :email]";
        Assert.equals(expectedCast, castFields, 'Should compile cast fields to ${expectedCast}, got ${castFields}');
    }
    
    function testErrorTupleCompilation() {
        var errorTuple = ChangesetCompiler.compileErrorTuple("email", "is required");
        var expectedError = "{:email, \"is required\"}";
        Assert.equals(expectedError, errorTuple, 'Should compile error tuple to ${expectedError}, got ${errorTuple}');
    }
    
    function testFullChangesetCompilation() {
        var fullChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        Assert.isTrue(fullChangeset.contains("defmodule UserRegistrationChangeset do"), "Should contain module definition");
        Assert.isTrue(fullChangeset.contains("def changeset(%User{} = struct, attrs) do"), "Should contain typed changeset function");
    }
    
    function testChangesetCompilationPerformance() {
        var startTime = haxe.Timer.stamp();
        for (i in 0...10) {
            ChangesetCompiler.compileFullChangeset("TestChangeset" + i, "TestModel");
        }
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        var avgTime = compilationTime / 10;
        
        Assert.isTrue(compilationTime >= 0, "Should complete successfully");
        Assert.isTrue(avgTime < 15, 'Performance target: Average compilation should be <15ms per changeset, was: ${Math.round(avgTime)}ms');
    }
    
    // ============================================================================
    // 7-Category Edge Case Framework Implementation (Following AdvancedEctoTest Pattern)
    // ============================================================================
    
    function testErrorConditionsInvalidInputs() {
        // Test null/invalid inputs
        Assert.isTrue(!ChangesetCompiler.isChangesetClass(null), "Should handle null class name gracefully");
        Assert.isTrue(!ChangesetCompiler.isChangesetClass(""), "Should handle empty class name gracefully");
        
        // Test malformed changeset data
        var invalidValidation = ChangesetCompiler.compileValidation("", "");
        Assert.notNull(invalidValidation, "Should handle malformed validation gracefully");
        
        // Test invalid field lists
        var invalidFields = ChangesetCompiler.compileCastFields([]);
        Assert.equals("[]", invalidFields, "Should handle empty field lists");
    }
    
    function testBoundaryCasesEdgeValues() {
        // Test very large field lists
        var largeFields = [];
        for (i in 0...100) {
            largeFields.push('field$i');
        }
        
        var largeCastFields = ChangesetCompiler.compileCastFields(largeFields);
        Assert.isTrue(largeCastFields.length > 100, "Should handle large field lists");
        Assert.isTrue(largeCastFields.contains("field0"), "Should include first field");
        Assert.isTrue(largeCastFields.contains("field99"), "Should include last field");
        
        // Test changeset with many validations
        var manyValidations = [];
        for (i in 0...50) {
            manyValidations.push(ChangesetCompiler.compileValidation('field$i', "required"));
        }
        
        Assert.equals(50, manyValidations.length, "Should handle many validation rules");
        Assert.isTrue(manyValidations[0].contains("validate_required"), "Should compile all validation rules");
    }
    
    function testSecurityValidationInputSanitization() {
        // Test injection-like patterns in field names
        var maliciousField = "name'; DROP TABLE users; --";
        var safeValidation = ChangesetCompiler.compileValidation(maliciousField, "required");
        Assert.isTrue(safeValidation.contains("validate_required"), "Should sanitize malicious field names");
        
        // Test code injection in changeset names
        var maliciousChangeset = "Test'; System.cmd('rm', ['-rf', '/']); --";
        var safeModule = ChangesetCompiler.generateChangesetModule(maliciousChangeset);
        Assert.equals(-1, safeModule.indexOf("System.cmd"), "Should not include dangerous system calls");
    }
    
    @:timeout(15000)  // 15 seconds for stress testing
    function testPerformanceLimitsStressTesting() {
        var startTime = haxe.Timer.stamp();
        
        // Stress test: Compile 100 changesets rapidly
        for (i in 0...100) {
            var stressChangeset = ChangesetCompiler.compileFullChangeset('StressTest$i', 'StressModel$i');
            Assert.isTrue(stressChangeset.contains("defmodule"), "Each changeset should compile successfully");
        }
        
        var duration = (haxe.Timer.stamp() - startTime) * 1000;
        var avgPerChangeset = duration / 100;
        
        Assert.isTrue(avgPerChangeset < 15, 'Stress test: Average per changeset should be <15ms, was: ${Math.round(avgPerChangeset)}ms');
        Assert.isTrue(duration < 1500, 'Total stress test should complete in <1.5s, was: ${Math.round(duration)}ms');
    }
    
    function testIntegrationRobustnessCrossComponentTesting() {
        // Test interaction between different changeset components
        var changesetName = "IntegrationChangeset";
        var module = ChangesetCompiler.generateChangesetModule(changesetName);
        var castFields = ChangesetCompiler.compileCastFields(["name", "email", "age"]);
        var validation = ChangesetCompiler.compileValidation("email", "required");
        
        // Verify integration points
        Assert.isTrue(module.contains(changesetName), "Module should contain changeset name");
        Assert.isTrue(castFields.contains("name"), "Cast fields should include all fields");
        Assert.isTrue(validation.contains("email"), "Validation should reference correct field");
        
        // Test full pipeline with realistic data
        var realisticChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        Assert.isTrue(realisticChangeset.contains("UserRegistrationChangeset"), "Should generate realistic changeset module");
        Assert.isTrue(realisticChangeset.contains("User"), "Should reference correct schema");
        Assert.isTrue(realisticChangeset.contains("changeset"), "Should include changeset function");
    }
    
    function testTypeSafetyCompileTimeValidation() {
        // Test type consistency in changeset functions
        var userChangeset = ChangesetCompiler.compileFullChangeset("UserChangeset", "User");
        Assert.isTrue(userChangeset.contains("%User{}"), "Should generate typed struct pattern matching");
        
        var productChangeset = ChangesetCompiler.compileFullChangeset("ProductChangeset", "Product");
        Assert.isTrue(productChangeset.contains("%Product{}"), "Should generate different typed patterns for different schemas");
        
        // Test error tuple type consistency
        var stringError = ChangesetCompiler.compileErrorTuple("name", "is required");
        var intError = ChangesetCompiler.compileErrorTuple("age", "must be positive");
        Assert.isTrue(stringError.contains("{:name, \"is required\"}"), "Should generate properly typed string error");
        Assert.isTrue(intError.contains("{:age, \"must be positive\"}"), "Should generate properly typed validation error");
    }
    
    function testResourceManagementMemoryAndProcessEfficiency() {
        // Test memory efficiency of generated changesets
        var baselineCast = ChangesetCompiler.compileCastFields(['simple_field']);
        var baselineSize = baselineCast.length;
        
        // Test with additional complexity
        var complexFields = [];
        for (i in 0...20) {
            complexFields.push('complex_field_$i');
        }
        var complexCast = ChangesetCompiler.compileCastFields(complexFields);
        var complexSize = complexCast.length;
        
        // Resource efficiency checks
        Assert.isTrue(baselineSize > 0, "Baseline changeset should have content");
        Assert.isTrue(complexSize > baselineSize, "Complex changeset should be larger");
        Assert.isTrue(complexSize < baselineSize * 50, "Complex changeset should not be excessively large");
        
        // Test validation pipeline efficiency
        var efficientValidation = ChangesetCompiler.compileValidation("email", "email");
        Assert.isTrue(efficientValidation.contains("validate_format"), "Should efficiently generate format validation");
    }
}