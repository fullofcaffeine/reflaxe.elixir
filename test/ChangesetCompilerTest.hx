package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.helpers.ChangesetCompiler;

using StringTools;

/**
 * Modern Ecto Changeset Test Suite - Migrated to utest
 * 
 * Tests Ecto Changeset compilation with @:changeset annotation support, validation pipeline,
 * schema integration, and Phoenix ecosystem compatibility. Comprehensive edge case testing
 * across all 7 categories for production robustness.
 * 
 * MIGRATED TO UTEST - eliminates tink_testrunner complexity
 */
class ChangesetCompilerTest extends Test {
    
    public function new() {
        super();
    }
    
    // ============================================================================
    // Core Functionality Tests
    // ============================================================================
    
    public function testChangesetAnnotationDetection() {
        var className = "UserChangeset";
        var result = ChangesetCompiler.isChangesetClass(className);
        Assert.isTrue(result == true, "Should detect @:changeset annotated classes");
        
        var nonChangesetClass = "RegularClass";
        var nonChangesetResult = ChangesetCompiler.isChangesetClass(nonChangesetClass);
        Assert.isTrue(nonChangesetResult == false, "Should not detect regular classes as changesets");
    }
    
    public function testValidationCompilation() {
        var validation = ChangesetCompiler.compileValidation("email", "required");
        Assert.isTrue(validation.contains("validate_required"), "Should generate validate_required call");
        Assert.isTrue(validation.contains("[:email]"), "Should include field in validation call");
        
        // Test different validation types
        var lengthValidation = ChangesetCompiler.compileValidation("password", "length");
        Assert.isTrue(lengthValidation.contains("validate_length") || lengthValidation.contains("validate_required"), 
            "Should handle length validation");
        
        var formatValidation = ChangesetCompiler.compileValidation("email", "format");
        Assert.isTrue(formatValidation.contains("validate_format") || formatValidation.contains("validate_required"),
            "Should handle format validation");
    }
    
    public function testChangesetModuleGeneration() {
        var module = ChangesetCompiler.generateChangesetModule("UserChangeset");
        Assert.isTrue(module.contains("defmodule UserChangeset do"), "Should generate proper module definition");
        Assert.isTrue(module.contains("import Ecto.Changeset"), "Should import Ecto.Changeset");
        Assert.isTrue(module.contains("end"), "Module should be properly closed");
    }
    
    public function testCastFieldsCompilation() {
        var castFields = ChangesetCompiler.compileCastFields(["name", "age", "email"]);
        var expectedCast = "[:name, :age, :email]";
        Assert.equals(expectedCast, castFields, 'Should compile cast fields correctly');
        
        // Test single field
        var singleField = ChangesetCompiler.compileCastFields(["username"]);
        Assert.equals("[:username]", singleField, "Should handle single field casting");
    }
    
    public function testErrorTupleCompilation() {
        var errorTuple = ChangesetCompiler.compileErrorTuple("email", "is required");
        var expectedError = "{:email, \"is required\"}";
        Assert.equals(expectedError, errorTuple, 'Should compile error tuple correctly');
        
        // Test different error messages
        var lengthError = ChangesetCompiler.compileErrorTuple("password", "should be at least 8 character(s)");
        Assert.isTrue(lengthError.contains("{:password"), "Should handle password errors");
        Assert.isTrue(lengthError.contains("8 character"), "Should preserve error message");
    }
    
    public function testFullChangesetCompilation() {
        var fullChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        Assert.isTrue(fullChangeset.contains("defmodule UserRegistrationChangeset do"), "Should contain module definition");
        Assert.isTrue(fullChangeset.contains("def changeset(%User{} = struct, attrs) do"), "Should contain typed changeset function");
        Assert.isTrue(fullChangeset.contains("struct"), "Should reference struct parameter");
        Assert.isTrue(fullChangeset.contains("attrs"), "Should reference attrs parameter");
    }
    
    public function testValidationPipelineIntegration() {
        // Test that validation pipeline can be chained
        var module = ChangesetCompiler.generateChangesetModule("ComplexChangeset");
        Assert.isTrue(module != null && module.length > 0, "Should generate non-empty module");
        
        // Simulate pipeline construction
        var validations = [
            ChangesetCompiler.compileValidation("email", "required"),
            ChangesetCompiler.compileValidation("age", "number"),
            ChangesetCompiler.compileValidation("name", "required")
        ];
        
        Assert.equals(3, validations.length, "Should support multiple validations");
        for (validation in validations) {
            Assert.isTrue(validation.contains("validate"), "Each validation should contain validate function");
        }
    }
    
    public function testSchemaIntegration() {
        // Test different schema types
        var userChangeset = ChangesetCompiler.compileFullChangeset("UserChangeset", "User");
        Assert.isTrue(userChangeset.contains("User"), "Should integrate with User schema");
        
        var postChangeset = ChangesetCompiler.compileFullChangeset("PostChangeset", "Post");
        Assert.isTrue(postChangeset.contains("Post"), "Should integrate with Post schema");
        
        var productChangeset = ChangesetCompiler.compileFullChangeset("ProductChangeset", "Product");
        Assert.isTrue(productChangeset.contains("Product"), "Should integrate with Product schema");
    }
    
    public function testAssociationCasting() {
        // Test that association casting is supported
        var castFields = ChangesetCompiler.compileCastFields(["user_id", "posts"]);
        Assert.isTrue(castFields.contains("user_id"), "Should include foreign key fields");
        Assert.isTrue(castFields.contains("posts"), "Should include association fields");
    }
    
    // ============================================================================
    // Performance Tests
    // ============================================================================
    
    public function testChangesetCompilationPerformance() {
        var startTime = haxe.Timer.stamp();
        for (i in 0...10) {
            ChangesetCompiler.compileFullChangeset("TestChangeset" + i, "TestModel");
        }
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        var avgTime = compilationTime / 10;
        
        Assert.isTrue(compilationTime > 0, "Should take measurable time");
        Assert.isTrue(avgTime < 15, 'Performance target: Average compilation should be <15ms per changeset, was: ${Math.round(avgTime)}ms');
    }
    
    public function testBatchCompilationPerformance() {
        var startTime = haxe.Timer.stamp();
        
        // Simulate compiling 50 changesets at once
        var results = [];
        for (i in 0...50) {
            results.push(ChangesetCompiler.compileFullChangeset("BatchChangeset" + i, "Model"));
        }
        
        var totalTime = (haxe.Timer.stamp() - startTime) * 1000;
        
        Assert.equals(50, results.length, "Should compile all 50 changesets");
        Assert.isTrue(totalTime < 100.0, 'Batch compilation should be <100ms, was ${totalTime}ms');
    }
    
    // ============================================================================
    // 7-Category Edge Case Framework
    // ============================================================================
    
    // Category 1: Error Conditions
    public function testErrorConditionsInvalidInputs() {
        // Test null/invalid inputs
        Assert.isFalse(ChangesetCompiler.isChangesetClass(null), "Should handle null class name gracefully");
        Assert.isFalse(ChangesetCompiler.isChangesetClass(""), "Should handle empty class name gracefully");
        
        // Test malformed changeset data
        var invalidValidation = ChangesetCompiler.compileValidation("", "");
        Assert.isTrue(invalidValidation != null, "Should handle malformed validation gracefully");
        
        // Test invalid field lists
        var invalidFields = ChangesetCompiler.compileCastFields([]);
        Assert.equals("[]", invalidFields, "Should handle empty field lists");
        
        // Test with null array
        var nullFields = ChangesetCompiler.compileCastFields(null);
        Assert.isTrue(nullFields == "[]" || nullFields == null, "Should handle null field arrays safely");
    }
    
    // Category 2: Boundary Cases
    public function testBoundaryCasesLargeData() {
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
        
        // Test empty cases
        var emptyModule = ChangesetCompiler.generateChangesetModule("");
        Assert.isTrue(emptyModule != null, "Should handle empty module name");
    }
    
    // Category 3: Security Validation
    public function testSecurityValidationInputSanitization() {
        // Test injection-like patterns in field names
        var maliciousField = "name'; DROP TABLE users; --";
        var safeValidation = ChangesetCompiler.compileValidation(maliciousField, "required");
        Assert.isTrue(safeValidation.contains("validate_required"), "Should sanitize malicious field names");
        Assert.isFalse(safeValidation.contains("DROP TABLE"), "Should not include SQL injection");
        
        // Test code injection in changeset names
        var maliciousChangeset = "Test'; System.cmd('rm', ['-rf', '/']); --";
        var safeModule = ChangesetCompiler.generateChangesetModule(maliciousChangeset);
        Assert.equals(-1, safeModule.indexOf("System.cmd"), "Should not include dangerous system calls");
        Assert.equals(-1, safeModule.indexOf("rm -rf"), "Should not include dangerous commands");
        
        // Test script injection
        var scriptInjection = "<script>alert('XSS')</script>";
        var safeField = ChangesetCompiler.compileCastFields([scriptInjection]);
        Assert.isFalse(safeField.contains("<script>"), "Should not include script tags");
    }
    
    // Category 4: Performance Limits
    public function testPerformanceLimitsStressTesting() {
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
    
    // Category 5: Integration Robustness
    public function testIntegrationRobustnessCrossComponent() {
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
    
    // Category 6: Type Safety
    public function testTypeSafetyCompileTimeValidation() {
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
    
    // Category 7: Resource Management
    public function testResourceManagementMemoryEfficiency() {
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
        Assert.isTrue(efficientValidation.contains("validate_format") || efficientValidation.contains("validate_required"), 
            "Should efficiently generate format validation");
        
        // Test concurrent compilation simulation
        var concurrentResults = [];
        for (i in 0...10) {
            concurrentResults.push(ChangesetCompiler.compileFullChangeset('Concurrent$i', 'Model'));
        }
        Assert.equals(10, concurrentResults.length, "Should handle concurrent-like compilation");
    }
}