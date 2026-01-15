import ecto.Migration;

/**
 * Negative test: schema validation should catch typos when migrations define the DB schema.
 *
 * Expected: compilation fails with helpful errors (unknown table).
 */
@:migration
class CreateUsers extends Migration {
    public function up(): Void {
        createTable("users").addColumn("email", ecto.Migration.ColumnType.String(), {nullable: false});
    }

    public function down(): Void {
        dropTable("users");
    }
}

@:schema("userz")
class User {
    public var id: Int;
    public var email: String;
}

class Main {
    static function main() {}
}

