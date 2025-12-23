package migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * Example migration using the typed Ecto Migration DSL (`std/ecto/Migration.hx`).
 */
@:migration({timestamp: "20240101120000"})
class CreateUsers extends Migration {
    public function new() {}

    public function up(): Void {
        createTable("users")
            .addId()
            .addColumn("name", ColumnType.String(), {nullable: false})
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addColumn("age", ColumnType.Integer)
            .addColumn("active", ColumnType.Boolean, {defaultValue: true})
            .addTimestamps()
            .addIndex(["email"], {unique: true})
            .addIndex(["name", "active"]);
    }

    public function down(): Void {
        dropTable("users");
    }
}
