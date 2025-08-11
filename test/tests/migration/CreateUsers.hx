package;

/**
 * Migration compiler test case
 * Tests @:migration annotation compilation
 */
@:migration("users")
class CreateUsers {
	public function up(): Void {
		// Create table with columns
		// The migration compiler will transform these into proper Ecto.Migration calls
		createTable("users");
		addColumn("users", "id", "serial", true, null); // primary_key
		addColumn("users", "name", "string", false, null); // not null
		addColumn("users", "email", "string", false, null); // not null  
		addColumn("users", "age", "integer", null, 0); // default: 0
		addColumn("users", "bio", "text", null, null);
		addColumn("users", "active", "boolean", null, true); // default: true
		addTimestamps("users");
		
		// Add indexes
		addIndex("users", ["email"], {unique: true});
		addIndex("users", ["name", "active"]);
		
		// Add constraints
		addCheckConstraint("users", "age_check", "age >= 0 AND age <= 150");
	}
	
	public function down(): Void {
		// Drop table (automatically drops indexes and constraints)
		dropTable("users");
	}
	
	// Helper functions (provided by MigrationDSL)
	function createTable(name: String): Void {}
	function addColumn(table: String, name: String, type: String, ?primaryKey: Bool, ?defaultValue: Dynamic): Void {}
	function addTimestamps(table: String): Void {}
	function dropTable(name: String): Void {}
	function addIndex(table: String, columns: Array<String>, ?options: Dynamic): Void {}
	function addCheckConstraint(table: String, name: String, condition: String): Void {}
}