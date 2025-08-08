package test;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import reflaxe.elixir.macro.EctoQueryMacros;

using StringTools;

/**
 * Simple test for basic Ecto query compilation
 */
class SimpleQueryCompilationTest {
    public static function main() {
        trace("Testing basic Ecto query compilation...");
        
        testSimpleWhereQuery();
        testSimpleSelectQuery();
        testBasicJoinQuery();
        
        trace("✅ Basic Ecto query compilation tests completed");
    }
    
    static function testSimpleWhereQuery() {
        trace("TEST: Simple where clause");
        
        var condition = EctoQueryMacros.analyzeCondition(macro u -> u.age > 18);
        var whereQuery = EctoQueryMacros.generateWhereQuery(condition);
        
        trace('Generated where query: ${whereQuery}');
        
        assertTrue(whereQuery.contains("|>"), "Should use pipe syntax");
        assertTrue(whereQuery.contains("where("), "Should include where function");
        assertTrue(whereQuery.contains("[u]"), "Should include binding array");
        assertTrue(whereQuery.contains("u.age"), "Should include field access");
        assertTrue(whereQuery.contains(">"), "Should include operator");
        assertTrue(whereQuery.contains("^18"), "Should include pinned parameter");
        
        trace("  ✓ Simple where clause working correctly");
    }
    
    static function testSimpleSelectQuery() {
        trace("TEST: Simple select clause");
        
        var select = EctoQueryMacros.analyzeSelectExpression(macro u -> u.name);
        var selectQuery = EctoQueryMacros.generateSelectQuery(select);
        
        trace('Generated select query: ${selectQuery}');
        
        assertTrue(selectQuery.contains("|>"), "Should use pipe syntax");
        assertTrue(selectQuery.contains("select("), "Should include select function");
        assertTrue(selectQuery.contains("[u]"), "Should include binding array");
        assertTrue(selectQuery.contains("u.name"), "Should include field access");
        
        trace("  ✓ Simple select clause working correctly");
    }
    
    static function testBasicJoinQuery() {
        trace("TEST: Basic join clause");
        
        var join = {
            schema: "Post",
            alias: "posts", 
            type: "inner",
            on: "user.id == posts.user_id"
        };
        var joinQuery = EctoQueryMacros.generateJoinQuery(join);
        
        trace('Generated join query: ${joinQuery}');
        
        assertTrue(joinQuery.contains("|>"), "Should use pipe syntax");
        assertTrue(joinQuery.contains("join("), "Should include join function");
        assertTrue(joinQuery.contains("assoc("), "Should use association join");
        assertTrue(joinQuery.contains(":posts"), "Should reference association");
        
        trace("  ✓ Basic join clause working correctly");
    }
    
    // Helper assertion functions
    static function assertTrue(condition: Bool, message: String): Void {
        if (!condition) {
            throw 'Assertion failed: ${message}';
        }
    }
}

#end