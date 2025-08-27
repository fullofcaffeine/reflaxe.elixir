package example_migrations;

// Temporarily simplified to debug compilation hang
// import reflaxe.elixir.helpers.MigrationDSL;

/**
 * Example migration using Haxe→Elixir Migration DSL
 * Temporarily simplified to debug compilation hang issue
 */
@:migration
class CreateUsers {
    public static function up(): String {
        return "create table(:users) do\n  add :id, :serial, primary_key: true\nend";
    }
    
    public static function down(): String {
        return "drop table(:users)";
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        // Empty main for testing
    }
}