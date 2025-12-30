package;

import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20240101120000"})
class CreateUsers extends Migration {
    public function up(): Void {
        createTable("users")
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addColumn("active", ColumnType.Boolean, {defaultValue: true})
            .addTimestamps()
            .addIndex(["email"], {unique: true});
    }

    public function down(): Void {
        dropTable("users");
    }
}

