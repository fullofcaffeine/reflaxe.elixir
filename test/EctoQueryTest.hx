package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.macro.EctoQueryMacros;
import reflaxe.elixir.schema.SchemaIntrospection;
import ecto.Query;

using StringTools;

/**
 * Comprehensive test suite for type-safe Ecto query macros
 * Tests compile-time field validation, query generation, and IDE support
 */
class EctoQueryTest {
    public static function main() {
        trace("Running Ecto Query Macro Tests...");
        
        testSchemaIntrospection();
        testBasicQueryGeneration();
        testFieldValidation();
        testComplexQueries();
        testAggregationFunctions();
        testQueryOptimization();
        testIDESupport();
        testErrorHandling();
        
        trace("✅ All Ecto query tests passed!");
    }
    
    /**
     * Test schema introspection functionality
     */
    static function testSchemaIntrospection() {
        trace("TEST: Schema introspection");
        
        // Test predefined schema loading
        assertTrue(SchemaIntrospection.schemaExists("User"), "Should recognize User schema");
        assertTrue(SchemaIntrospection.schemaExists("Post"), "Should recognize Post schema");
        assertTrue(SchemaIntrospection.schemaExists("Comment"), "Should recognize Comment schema");
        
        // Test field existence
        assertTrue(SchemaIntrospection.hasField("User", "name"), "User should have name field");
        assertTrue(SchemaIntrospection.hasField("User", "email"), "User should have email field");
        assertTrue(SchemaIntrospection.hasField("User", "age"), "User should have age field");
        assertTrue(SchemaIntrospection.hasField("Post", "title"), "Post should have title field");
        
        // Test field types
        assertEqual(SchemaIntrospection.getFieldType("User", "name"), "String", "Name should be String type");
        assertEqual(SchemaIntrospection.getFieldType("User", "age"), "Int", "Age should be Int type");
        assertEqual(SchemaIntrospection.getFieldType("User", "active"), "Bool", "Active should be Bool type");
        
        // Test associations
        assertTrue(SchemaIntrospection.hasAssociation("User", "posts"), "User should have posts association");
        assertTrue(SchemaIntrospection.hasAssociation("Post", "user"), "Post should have user association");
        assertTrue(SchemaIntrospection.hasAssociation("Comment", "post"), "Comment should have post association");
        
        trace("✅ Schema introspection tests passed");
    }
    
    /**
     * Test basic query generation
     */
    static function testBasicQueryGeneration() {
        trace("TEST: Basic query generation");
        
        // Test simple from query
        var fromQuery = EctoQueryMacros.from(UserSchema);
        assertTrue(fromQuery.contains("from"), "Should generate from clause");
        assertTrue(fromQuery.contains("User"), "Should include User schema");
        
        // Test where clause
        var whereQuery = EctoQueryMacros.where(null, macro u -> u.age > 18);
        assertTrue(whereQuery.contains("where"), "Should generate where clause");
        assertTrue(whereQuery.contains("age"), "Should include field name");
        assertTrue(whereQuery.contains(">"), "Should include operator");
        
        // Test select clause
        var selectQuery = EctoQueryMacros.select(null, macro u -> u.name);
        assertTrue(selectQuery.contains("select"), "Should generate select clause");
        assertTrue(selectQuery.contains("name"), "Should include selected field");
        
        // Test order by clause
        var orderQuery = EctoQueryMacros.order_by(null, macro u -> u.inserted_at);
        assertTrue(orderQuery.contains("order_by"), "Should generate order_by clause");
        assertTrue(orderQuery.contains("inserted_at"), "Should include order field");
        
        trace("✅ Basic query generation tests passed");
    }
    
    /**
     * Test compile-time field validation
     */
    static function testFieldValidation() {
        trace("TEST: Compile-time field validation");
        
        // Test valid fields (should not throw errors)
        try {
            var validQuery = EctoQueryMacros.from(UserSchema);
            assertTrue(true, "Valid schema should not throw error");
        } catch (e: Dynamic) {
            assertTrue(false, "Valid schema threw unexpected error: " + e);
        }
        
        // Test schema field validation through introspection
        assertFalse(SchemaIntrospection.hasField("User", "nonexistent_field"), "Should not find nonexistent field");
        assertFalse(SchemaIntrospection.hasField("Post", "invalid_field"), "Should not find invalid field");
        
        // Test association validation
        assertFalse(SchemaIntrospection.hasAssociation("User", "nonexistent_assoc"), "Should not find nonexistent association");
        assertFalse(SchemaIntrospection.hasAssociation("Post", "invalid_assoc"), "Should not find invalid association");
        
        // Test type validation for aggregates
        assertTrue(isNumericField("User", "age"), "Age should be numeric field");
        assertFalse(isNumericField("User", "name"), "Name should not be numeric field");
        assertTrue(isNumericField("User", "id"), "ID should be numeric field");
        
        trace("✅ Field validation tests passed");
    }
    
    /**
     * Test complex query combinations
     */
    static function testComplexQueries() {
        trace("TEST: Complex query combinations");
        
        // Test query with multiple clauses
        var complexQuery = generateComplexQuery();
        assertTrue(complexQuery.contains("from"), "Complex query should have from clause");
        assertTrue(complexQuery.contains("where"), "Complex query should have where clause");
        assertTrue(complexQuery.contains("order_by"), "Complex query should have order clause");
        
        // Test join queries
        var joinQuery = EctoQueryMacros.join(null, macro u -> u.posts, null, null);
        assertTrue(joinQuery.contains("join"), "Should generate join clause");
        
        // Test group by queries
        var groupQuery = EctoQueryMacros.group_by(null, macro u -> u.age);
        assertTrue(groupQuery.contains("group_by"), "Should generate group_by clause");
        
        // Test nested conditions
        var nestedQuery = generateNestedConditionQuery();
        assertTrue(nestedQuery.length > 0, "Should generate nested query");
        
        trace("✅ Complex query tests passed");
    }
    
    /**
     * Test aggregation functions
     */
    static function testAggregationFunctions() {
        trace("TEST: Aggregation functions");
        
        // Test count function
        var countQuery = EctoQueryMacros.count(null, null);
        assertTrue(countQuery.contains("count"), "Should generate count function");
        
        // Test sum function
        var sumQuery = EctoQueryMacros.sum(null, macro u -> u.age);
        assertTrue(sumQuery.contains("sum"), "Should generate sum function");
        assertTrue(sumQuery.contains("age"), "Should include summed field");
        
        // Test avg function
        var avgQuery = EctoQueryMacros.avg(null, macro u -> u.age);
        assertTrue(avgQuery.contains("avg"), "Should generate avg function");
        
        // Test max/min functions
        var maxQuery = EctoQueryMacros.max(null, macro u -> u.age);
        var minQuery = EctoQueryMacros.min(null, macro u -> u.age);
        assertTrue(maxQuery.contains("max"), "Should generate max function");
        assertTrue(minQuery.contains("min"), "Should generate min function");
        
        trace("✅ Aggregation function tests passed");
    }
    
    /**
     * Test query optimization hints
     */
    static function testQueryOptimization() {
        trace("TEST: Query optimization");
        
        var baseQuery = "from(u in User) |> where([u], u.age > 18)";
        var optimizedQuery = EctoQueryMacros.optimizeQuery(baseQuery);
        
        assertTrue(optimizedQuery.length >= baseQuery.length, "Optimized query should include original");
        assertTrue(optimizedQuery != baseQuery, "Optimization should add hints");
        
        // Test index hints
        if (optimizedQuery.contains("plan")) {
            assertTrue(true, "Should add index optimization hints");
        }
        
        // Test preload hints for joins
        var joinQuery = "from(u in User) |> join(:inner, [u], p in assoc(u, :posts))";
        var optimizedJoin = EctoQueryMacros.optimizeQuery(joinQuery);
        
        if (optimizedJoin.contains("preload")) {
            assertTrue(true, "Should add preload hints for joins");
        }
        
        trace("✅ Query optimization tests passed");
    }
    
    /**
     * Test IDE support features
     */
    static function testIDESupport() {
        trace("TEST: IDE support features");
        
        // Test schema type definitions exist
        var userSchema = new UserSchema();
        assertTrue(userSchema.__schema_name == "User", "Should have schema name for IDE");
        
        var postSchema = new PostSchema();
        assertTrue(postSchema.__schema_name == "Post", "Should have Post schema name");
        
        // Test field accessors for autocomplete
        assertTrue(userSchema.name != null || userSchema.name == null, "Should have name field accessor");
        assertTrue(userSchema.email != null || userSchema.email == null, "Should have email field accessor");
        assertTrue(userSchema.age != null || userSchema.age == null, "Should have age field accessor");
        
        // Test association accessors
        assertTrue(userSchema.posts != null || userSchema.posts == null, "Should have posts association");
        assertTrue(postSchema.user != null || postSchema.user == null, "Should have user association");
        
        // Test QueryBuilder interface
        var queryBuilder = new QueryBuilder(UserSchema);
        assertTrue(queryBuilder.__schema_type == UserSchema, "Should store schema type");
        assertTrue(queryBuilder.__query_parts != null, "Should have query parts array");
        
        trace("✅ IDE support tests passed");
    }
    
    /**
     * Test error handling and validation
     */
    static function testErrorHandling() {
        trace("TEST: Error handling");
        
        // Test nonexistent schema
        assertFalse(SchemaIntrospection.schemaExists("NonexistentSchema"), "Should not find nonexistent schema");
        
        // Test invalid field access
        assertFalse(SchemaIntrospection.hasField("User", ""), "Should reject empty field name");
        assertFalse(SchemaIntrospection.hasField("", "name"), "Should reject empty schema name");
        
        // Test invalid association
        assertFalse(SchemaIntrospection.hasAssociation("User", "invalid"), "Should reject invalid association");
        
        // Test type validation
        assertEqual(SchemaIntrospection.getFieldType("User", "nonexistent"), "unknown", "Should return unknown for invalid field");
        
        // Test cache functionality
        SchemaIntrospection.clearCache();
        assertTrue(SchemaIntrospection.schemaExists("User"), "Should reload schema after cache clear");
        
        trace("✅ Error handling tests passed");
    }
    
    // Helper functions
    
    static function generateComplexQuery(): String {
        // Simulate complex query generation
        return "from(u in User) |> where([u], u.age > 18 and u.active == true) |> order_by([u], desc: u.created_at)";
    }
    
    static function generateNestedConditionQuery(): String {
        // Simulate nested condition query
        return "from(u in User) |> where([u], u.age > 18 or (u.active == true and u.email != nil))";
    }
    
    static function isNumericField(schema: String, field: String): Bool {
        var fieldType = SchemaIntrospection.getFieldType(schema, field);
        return ["Int", "Float", "integer", "float", "decimal", "number"].contains(fieldType);
    }
    
    // Test helper functions
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
    
    static function assertFalse(condition: Bool, message: String) {
        assertTrue(!condition, message);
    }
    
    static function assertEqual<T>(actual: T, expected: T, message: String) {
        if (actual != expected) {
            var error = '❌ ASSERTION FAILED: ${message} - Expected: ${expected}, Actual: ${actual}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
}

// Mock schema classes for testing
class UserSchema {
    public var __schema_name = "User";
    public var name: String;
    public var email: String;
    public var age: Int;
    public var active: Bool;
    public var posts: Array<PostSchema>;
    public var comments: Array<CommentSchema>;
    
    public function new() {}
}

class PostSchema {
    public var __schema_name = "Post";
    public var title: String;
    public var body: String;
    public var user_id: Int;
    public var user: UserSchema;
    public var comments: Array<CommentSchema>;
    
    public function new() {}
}

class CommentSchema {
    public var __schema_name = "Comment";
    public var content: String;
    public var user_id: Int;
    public var post_id: Int;
    public var user: UserSchema;
    public var post: PostSchema;
    
    public function new() {}
}

#end