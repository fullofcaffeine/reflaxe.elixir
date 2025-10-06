package;

import contexts.Users;

/**
 * Example 06: Complete User Management Context
 *
 * This example demonstrates:
 * - Ecto schema definition with @:schema annotation
 * - Field types and validation with @:field
 * - Changeset creation and validation with @:changeset
 * - CRUD operations (Create, Read, Update, Delete)
 * - Business logic in context modules
 * - Association handling (@:has_many)
 */
class Main {
	public static function main() {
		trace("=== User Management Context Example ===");

		// Demonstrate changeset creation
		trace("\n1. Changeset Creation:");
		var userChangeset = Users.change_user();
		trace('Changeset created: ${userChangeset.valid}');

		// Demonstrate user creation
		trace("\n2. User Creation:");
		var newUserAttrs = {
			name: "John Doe",
			email: "john@example.com",
			age: 30,
			active: true
		};
		var createResult = Users.create_user(newUserAttrs);
		trace('User creation status: ${createResult.status}');

		// Demonstrate user listing
		trace("\n3. List Users:");
		var allUsers = Users.list_users();
		trace('Total users: ${allUsers.length}');

		// Demonstrate user search
		trace("\n4. Search Users:");
		var searchResults = Users.search_users("john");
		trace('Search results: ${searchResults.length}');

		// Demonstrate filtering
		trace("\n5. Filter Active Users:");
		var activeUsers = Users.list_users({active: true, minAge: 18});
		trace('Active users (18+): ${activeUsers.length}');

		// Demonstrate user statistics
		trace("\n6. User Statistics:");
		var stats = Users.user_stats();
		trace('Total: ${stats.total}, Active: ${stats.active}, Inactive: ${stats.inactive}');

		// Demonstrate association preloading
		trace("\n7. Users with Posts:");
		var usersWithPosts = Users.users_with_posts();
		trace('Users with posts loaded: ${usersWithPosts.length}');

		trace("\n=== User management example completed successfully ===");
	}
}
