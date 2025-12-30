import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * Negative test: migration validation should catch typos.
 *
 * Expected: compilation fails with helpful errors (unknown table/column).
 */
@:migration
class BadMigration extends Migration {
    public function up(): Void {
        createTable("users")
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addTimestamps()
            .addIndex(["email"], {unique: true});

        createTable("posts")
            .addColumn("author_id", ColumnType.Integer)
            // Typo: should be "users"
            .addForeignKey("author_id", "userz");
    }

    public function down(): Void {
        dropTable("posts");
        dropTable("users");
    }
}

class Main {
    static function main() {}
}

