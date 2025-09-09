package;

import ecto.Query;
import ecto.Query.EctoQuery;

/**
 * Test for typed Ecto Query API
 * Validates that Query.from() properly handles schema modules
 * and that query building methods work correctly.
 */
class Main {
	public static function main() {
		// Test basic query creation from schema
		testBasicQuery();
		
		// Test query with where clause
		testWhereClause();
		
		// Test query with orderBy
		testOrderBy();
		
		// Test query with limit and offset
		testLimitOffset();
		
		// Test chained query operations
		testChainedOperations();
		
		// Test whereAll with multiple conditions
		testWhereAll();
	}
	
	static function testBasicQuery() {
		// Create a query from the User schema
		var query = Query.from(User);
		trace("Basic query created from User schema");
	}
	
	static function testWhereClause() {
		var query = Query.from(User);
		query = query.where("active", true);
		trace("Query with where clause for active users");
	}
	
	static function testOrderBy() {
		var query = Query.from(Post);
		query = query.orderBy("createdAt", "desc");
		trace("Query ordered by createdAt descending");
	}
	
	static function testLimitOffset() {
		var query = Query.from(Post);
		query = query.limit(10).offset(20);
		trace("Query with limit 10 and offset 20");
	}
	
	static function testChainedOperations() {
		var query = Query.from(User)
			.where("role", "admin")
			.orderBy("name", "asc")
			.limit(5);
		trace("Chained query operations");
	}
	
	static function testWhereAll() {
		var conditions = new Map<String, Dynamic>();
		conditions.set("active", true);
		conditions.set("role", "moderator");
		conditions.set("age", 25);
		
		var query = Query.from(User);
		query = Query.whereAll(query, conditions);
		trace("Query with multiple where conditions");
	}
}

// Test schema classes
@:schema
class User {
	var id: Int;
	var name: String;
	var email: String;
	var active: Bool;
	var role: String;
	var age: Int;
	var createdAt: Date;
}

@:schema 
class Post {
	var id: Int;
	var title: String;
	var content: String;
	var userId: Int;
	var createdAt: Date;
	var publishedAt: Date;
}