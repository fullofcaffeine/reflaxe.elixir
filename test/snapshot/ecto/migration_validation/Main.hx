import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * Test compile-time validation of migrations
 * This should fail to compile with helpful error messages
 */
@:migration
class TestMigration extends Migration {
    public function up(): Void {
        // Create first table
        createTable("users")
            .addColumn("id", ColumnType.Integer, {primaryKey: true, autoGenerate: true})
            .addColumn("name", ColumnType.String(), {nullable: false})
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addTimestamps()
            .addIndex(["email"], {unique: true});
        
        // Create second table with foreign key
        createTable("posts")
            .addColumn("id", ColumnType.Integer, {primaryKey: true, autoGenerate: true})
            .addColumn("title", ColumnType.String(), {nullable: false})
            .addColumn("content", ColumnType.Text)
            .addColumn("author_id", ColumnType.Integer)
            .addTimestamps()
            // TEST 1: This should fail - referencing wrong table name (userz instead of users)
            .addForeignKey("author_id", "userz");  // Typo: should be "users"
    }
    
    public function down(): Void {
        dropTable("posts");
        dropTable("users");
    }
}

@:migration  
class TestMigration2 extends Migration {
    public function up(): Void {
        createTable("comments")
            .addColumn("id", ColumnType.Integer, {primaryKey: true, autoGenerate: true})
            .addColumn("content", ColumnType.Text)
            .addColumn("post_id", ColumnType.Integer)
            // TEST 2: This should fail - indexing non-existent column
            .addIndex(["contet"], {unique: false});  // Typo: should be "content"
    }
    
    public function down(): Void {
        dropTable("comments");
    }
}

class Main {
    static function main() {
        trace("Testing migration compile-time validation");
    }
}