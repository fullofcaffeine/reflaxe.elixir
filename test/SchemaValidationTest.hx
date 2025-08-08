package test;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import reflaxe.elixir.macro.EctoQueryMacros;
import reflaxe.elixir.schema.SchemaIntrospection;

using StringTools;

/**
 * Test real schema validation integration with query macros
 */
class SchemaValidationTest {
    public static function main() {
        trace("Testing enhanced schema validation integration...");
        
        testValidFieldAccess();
        testInvalidFieldAccess();
        testOperatorTypeValidation();
        testAssociationValidation();
        testAvailableFieldsListing();
        
        trace("✅ Schema validation integration tests completed");
    }
    
    static function testValidFieldAccess() {
        trace("TEST: Valid field access");
        
        // These should work without errors (User schema has these fields)
        try {
            var condition = EctoQueryMacros.analyzeCondition(macro u -> u.age > 18);
            assertEqual(condition.fields[0], "age", "Should extract age field");
            
            var select = EctoQueryMacros.analyzeSelectExpression(macro u -> u.name);
            assertEqual(select.fields[0], "name", "Should extract name field");
            
            trace("  ✓ Valid fields processed correctly");
        } catch (e: Dynamic) {
            trace("  ❌ Unexpected error with valid fields: " + e);
        }
    }
    
    static function testInvalidFieldAccess() {
        trace("TEST: Invalid field access detection");
        
        // This test verifies our validation functions exist and can be called
        // In a real macro context, these would trigger Context.error()
        var hasNonexistentField = SchemaIntrospection.hasField("User", "nonexistent_field");
        assertFalse(hasNonexistentField, "Should not find nonexistent field");
        
        var hasValidField = SchemaIntrospection.hasField("User", "name");
        assertTrue(hasValidField, "Should find valid field 'name'");
        
        trace("  ✓ Field validation working correctly");
    }
    
    static function testOperatorTypeValidation() {
        trace("TEST: Operator type validation");
        
        // Test helper functions for type validation
        assertTrue(EctoQueryMacros.isNumericOperator(">"), "Should recognize > as numeric");
        assertTrue(EctoQueryMacros.isNumericOperator("<="), "Should recognize <= as numeric");
        assertFalse(EctoQueryMacros.isNumericOperator("=="), "Should not consider == as numeric-only");
        
        assertTrue(EctoQueryMacros.isStringOperator("like"), "Should recognize 'like' as string operator");
        assertTrue(EctoQueryMacros.isStringOperator("ilike"), "Should recognize 'ilike' as string operator");
        
        assertTrue(EctoQueryMacros.isStringType("String"), "Should recognize String type");
        assertTrue(EctoQueryMacros.isStringType("text"), "Should recognize text type");
        assertFalse(EctoQueryMacros.isStringType("Int"), "Should not consider Int as string");
        
        trace("  ✓ Operator type validation working correctly");
    }
    
    static function testAssociationValidation() {
        trace("TEST: Association validation");
        
        // Test association checking
        var hasPostsAssoc = SchemaIntrospection.hasAssociation("User", "posts");
        assertTrue(hasPostsAssoc, "User should have posts association");
        
        var hasInvalidAssoc = SchemaIntrospection.hasAssociation("User", "invalid_assoc");
        assertFalse(hasInvalidAssoc, "Should not find invalid association");
        
        trace("  ✓ Association validation working correctly");
    }
    
    static function testAvailableFieldsListing() {
        trace("TEST: Available fields listing for error messages");
        
        // Test helper functions that provide better error messages
        var availableFields = EctoQueryMacros.getAvailableFields("User");
        assertTrue(availableFields.length > 0, "Should have available fields for User");
        assertTrue(availableFields.contains("name"), "Should include 'name' field");
        assertTrue(availableFields.contains("email"), "Should include 'email' field");
        assertTrue(availableFields.contains("age"), "Should include 'age' field");
        
        var availableAssocs = EctoQueryMacros.getAvailableAssociations("User");
        assertTrue(availableAssocs.length > 0, "Should have available associations for User");
        assertTrue(availableAssocs.contains("posts"), "Should include 'posts' association");
        
        trace("  ✓ Available fields/associations listing working correctly");
    }
    
    // Helper assertion functions
    static function assertTrue(condition: Bool, message: String): Void {
        if (!condition) {
            throw 'Assertion failed: ${message}';
        }
    }
    
    static function assertFalse(condition: Bool, message: String): Void {
        if (condition) {
            throw 'Assertion failed (expected false): ${message}';
        }
    }
    
    static function assertEqual<T>(actual: T, expected: T, message: String): Void {
        if (actual != expected) {
            throw 'Assertion failed: ${message}. Expected: ${expected}, Got: ${actual}';
        }
    }
}

#end