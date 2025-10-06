package;

import example_migrations.CreateUsers;

/**
 * Example 04: Ecto Migration Integration
 *
 * This example demonstrates:
 * - Database migration creation using @:migration annotation
 * - Table creation with proper column types
 * - Standard Ecto patterns (timestamps, etc.)
 * - Migration up/down operations
 */
class Main {
	public static function main() {
		trace("=== Ecto Migration Example ===");

		// Demonstrate migration up operation
		trace("Migration Up Operation:");
		var upSQL = CreateUsers.up();
		trace(upSQL);

		// Demonstrate migration down operation
		trace("\nMigration Down Operation:");
		var downSQL = CreateUsers.down();
		trace(downSQL);

		trace("\n=== Migration example completed successfully ===");
	}
}
