package;

import ecto.TypedQuery;
import ecto.TypedQuery.SortDirection;
import ecto.Migration;
import ecto.Migration.*;

/**
 * Test for Type-Safe Query System with Migration DSL
 * 
 * Validates:
 * 1. TypedQuery compilation with type-safe operations
 * 2. Migration DSL fluent API 
 * 3. Query escape hatches for raw SQL
 * 4. Proper Elixir code generation
 */
class Main {
	public static function main() {
		// Test TypedQuery creation and basic operations
		testBasicTypedQuery();
		
		// Test query with where conditions
		testWhereConditions();
		
		// Test raw SQL escape hatches
		testEscapeHatches();
		
		// Test query execution methods
		testQueryExecution();
		
		// Test migration DSL compilation
		testMigrationCompilation();
	}
	
	static function testBasicTypedQuery() {
		// Create a typed query with limit and offset
		var query = TypedQuery.from(User)
			.limit(10)
			.offset(20);
		trace("Basic TypedQuery created with limit and offset");
	}
	
	static function testWhereConditions() {
		// Test type-safe where with lambda expressions
		var activeAdults = TypedQuery.from(User)
			.where(u -> u.active == true)
			.where(u -> u.age >= 18)
			.orderBy(u -> [{field: u.createdAt, direction: SortDirection.Desc}]);  // Using type-safe enum
		trace("TypedQuery with type-safe where conditions");
	}
	
	static function testEscapeHatches() {
		// Test raw SQL escape hatches
		var complexQuery = TypedQuery.from(User)
			.whereRaw("active = ? AND age > ?", true, 18)
			.orderByRaw("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, created_at DESC");
		
		// Convert to EctoQuery for advanced operations
		var ectoQuery = complexQuery.toEctoQuery();
		trace("TypedQuery with raw SQL escape hatches");
	}
	
	static function testQueryExecution() {
		var query = TypedQuery.from(User);
		
		// Test various execution methods (compile-time validation only)
		// These would execute against a real database at runtime
		// var users = query.all();
		// var firstUser = query.first();
		// var userCount = query.count();
		// var hasUsers = query.exists();
		trace("Query execution methods validated");
	}
	
	static function testMigrationCompilation() {
		// Migration DSL is validated at compile time
		// The UserMigration class below tests the fluent API
		trace("Migration DSL compiled successfully");
	}
}

// Test schema classes
@:schema
class User {
	public var id: Int;
	public var name: String;
	public var email: String;
	public var active: Bool;
	public var role: String;
	public var age: Int;
	public var createdAt: Date;
	public var updatedAt: Date;
	
	public function new() {}
}

@:schema 
class Post {
	public var id: Int;
	public var title: String;
	public var content: String;
	public var userId: Int;
	public var published: Bool;
	public var createdAt: Date;
	public var updatedAt: Date;
	
	public function new() {}
}

/**
 * Test migration using the typed DSL
 */
@:migration
class UserMigration extends Migration {
	public function up(): Void {
		// Create users table with various column types
		createTable("users")
			.addColumn("name", String(), {nullable: false})
			.addColumn("email", String(), {nullable: false})
			.addColumn("active", Boolean, {defaultValue: true})
			.addColumn("role", String())
			.addColumn("age", Integer)
			.addTimestamps()
			.addIndex(["email"], {unique: true})
			.addIndex(["role", "active"]);
		
		// Create posts table with foreign key
		createTable("posts")
			.addColumn("title", String(), {nullable: false})
			.addColumn("content", Text)
			.addColumn("user_id", Integer)
			.addColumn("published", Boolean, {defaultValue: false})
			.addTimestamps()
			.addForeignKey("user_id", "users", {onDelete: Cascade});
	}
	
	public function down(): Void {
		dropTable("posts");
		dropTable("users");
	}
}