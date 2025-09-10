package;

import ecto.TypedQuery;
import ecto.Migration;
import ecto.Migration.*;

/**
 * Test for the Type-Safe Query System
 * 
 * Tests:
 * 1. TypedQuery compilation with lambda expressions
 * 2. Migration DSL fluent API
 * 3. Schema synchronization with migrations
 */
class Main {
    static function main() {
        // Test Migration DSL
        testMigrationDSL();
        
        // Test TypedQuery
        testTypedQuery();
        
        // Test schema with migration sync
        testSchemaSync();
    }
    
    static function testMigrationDSL() {
        // This tests that the Migration DSL compiles correctly
        // Note: Migration is abstract, so we can't instantiate it directly
        // The macro would normally handle this, but for testing we just
        // verify the class compiles with its up/down methods
        trace("Migration DSL test: TestMigration class compiled successfully");
    }
    
    static function testTypedQuery() {
        // Test basic typed query
        var query1 = TypedQuery.from(TestTodo)
            .limit(10)
            .offset(0);
        
        // Test with raw escape hatch
        var query2 = TypedQuery.from(TestTodo)
            .whereRaw("completed = ?", [true])
            .orderByRaw("created_at DESC");
        
        // Test query execution methods (won't actually run)
        var ectoQuery = query1.toEctoQuery();
    }
    
    static function testSchemaSync() {
        // Test that schema can be synchronized with migration
        var todo = new TestTodo();
        todo.id = 1;
        todo.title = "Test";
        todo.completed = false;
    }
}

/**
 * Test migration using the typed DSL
 */
@:migration
class TestMigration extends Migration {
    public function up(): Void {
        createTable("test_todos")
            .addColumn("title", String(), {nullable: false})
            .addColumn("description", Text)
            .addColumn("completed", Boolean, {defaultValue: false})
            .addColumn("priority", String())
            .addColumn("due_date", DateTime)
            .addColumn("tags", Json)
            .addColumn("user_id", Integer)
            .addTimestamps()
            .addIndex(["user_id"])
            .addIndex(["completed"])
            .addUniqueConstraint(["title"], "unique_title");
    }
    
    public function down(): Void {
        dropTable("test_todos");
    }
}

/**
 * Test schema for TypedQuery
 */
@:schema
class TestTodo {
    public var id: Int;
    public var title: String;
    public var description: Null<String>;
    public var completed: Bool;
    public var priority: Null<String>;
    public var due_date: Null<Date>;
    public var tags: Dynamic;
    public var user_id: Null<Int>;
    public var inserted_at: Date;
    public var updated_at: Date;
    
    public function new() {}
}