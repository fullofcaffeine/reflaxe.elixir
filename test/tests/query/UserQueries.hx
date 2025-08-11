package;

/**
 * Query compiler test case
 * Tests Ecto query DSL compilation
 */
@:query
class UserQueries {
	// Simple select query
	public static function getAllUsers(): Dynamic {
		return from("users", "u", {
			select: "u"
		});
	}
	
	// Query with where clause
	public static function getActiveUsers(): Dynamic {
		return from("users", "u", {
			where: {active: true},
			select: "u"
		});
	}
	
	// Query with multiple conditions
	public static function getUsersByAge(minAge: Int, maxAge: Int): Dynamic {
		return from("users", "u", {
			where: {age_gte: minAge, age_lte: maxAge},
			select: "u"
		});
	}
	
	// Query with order and limit
	public static function getRecentUsers(limit: Int): Dynamic {
		return from("users", "u", {
			order_by: {created_at: "desc"},
			limit: limit,
			select: "u"
		});
	}
	
	// Query with join
	public static function getUsersWithPosts(): Dynamic {
		return from("users", "u", {
			join: {table: "posts", alias: "p", on: "p.user_id == u.id"},
			select: {user: "u", posts: "p"}
		});
	}
	
	// Query with left join
	public static function getUsersWithOptionalProfile(): Dynamic {
		return from("users", "u", {
			left_join: {table: "profiles", alias: "pr", on: "pr.user_id == u.id"},
			select: {user: "u", profile: "pr"}
		});
	}
	
	// Query with aggregation
	public static function getUserPostCounts(): Dynamic {
		return from("users", "u", {
			left_join: {table: "posts", alias: "p", on: "p.user_id == u.id"},
			group_by: "u.id",
			select: {user: "u", post_count: "count(p.id)"}
		});
	}
	
	// Query with having clause
	public static function getActivePosters(minPosts: Int): Dynamic {
		return from("users", "u", {
			left_join: {table: "posts", alias: "p", on: "p.user_id == u.id"},
			group_by: "u.id",
			having: 'count(p.id) >= $minPosts',
			select: {user: "u", post_count: "count(p.id)"}
		});
	}
	
	// Subquery example
	public static function getTopUsers(): Dynamic {
		var subquery = from("posts", "p", {
			group_by: "p.user_id",
			select: {user_id: "p.user_id", count: "count(p.id)"}
		});
		
		return from("users", "u", {
			join: {table: subquery, alias: "s", on: "s.user_id == u.id"},
			where: {count_gt: 10},
			select: "u"
		});
	}
	
	// Query with preload
	public static function getUsersWithAssociations(): Dynamic {
		return from("users", "u", {
			preload: ["posts", "profile", "comments"],
			select: "u"
		});
	}
	
	// Update query
	public static function deactivateOldUsers(days: Int): Dynamic {
		return from("users", "u", {
			where: {last_login_lt: 'ago($days, "day")'},
			update: {active: false}
		});
	}
	
	// Delete query
	public static function deleteInactiveUsers(): Dynamic {
		return from("users", "u", {
			where: {active: false},
			delete_all: true
		});
	}
	
	// Query with dynamic filters
	public static function searchUsers(filters: Dynamic): Dynamic {
		var query = from("users", "u", {select: "u"});
		
		if (filters.name != null) {
			query = where(query, "u", {name_ilike: filters.name});
		}
		
		if (filters.email != null) {
			query = where(query, "u", {email: filters.email});
		}
		
		if (filters.min_age != null) {
			query = where(query, "u", {age_gte: filters.min_age});
		}
		
		return query;
	}
	
	// Helper functions (would be provided by QueryCompiler)
	static function from(table: String, alias: String, opts: Dynamic): Dynamic { return null; }
	static function where(query: Dynamic, alias: String, condition: Dynamic): Dynamic { return null; }
}