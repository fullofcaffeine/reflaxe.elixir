import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * Test compile-time validation of migrations
 *
 * This test ensures the migration build macro can:
 * - track tables/columns through fluent builder chains, and
 * - validate references (foreign keys / indexes) in the happy path.
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
            .addForeignKey("author_id", "users");
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
            .addIndex(["content"], {unique: false});
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
